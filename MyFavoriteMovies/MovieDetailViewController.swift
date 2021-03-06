//
//  MovieDetailViewController.swift
//  MyFavoriteMovies
//
//  Created by Jarrod Parkes on 1/23/15.
//  Copyright (c) 2015 Udacity. All rights reserved.
//

import UIKit

// MARK: - MovieDetailViewController: UIViewController

class MovieDetailViewController: UIViewController {
    
    // MARK: Properties
    
    var appDelegate: AppDelegate!
    var isFavorite = false
    var selectedMovie: Movie?
    
    // MARK: Outlets
    
    @IBOutlet weak var posterImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var favoriteButton: UIButton!
    
    // MARK: Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // get the app delegate
        appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    }
    
    override func viewWillAppear(animated: Bool) {
        
        super.viewWillAppear(animated)
        
        if let selecteMovie = selectedMovie {
            
            // setting some defaults...
            posterImageView.image = UIImage(named: "film342.png")
            titleLabel.text = selecteMovie.title
            
            /* TASK A: Get favorite movies, then update the favorite buttons */
            /* 1A. Set the parameters */
            let methodParameters = [
                Constants.TMDBParameterKeys.ApiKey: Constants.TMDBParameterValues.ApiKey,
                Constants.TMDBParameterKeys.SessionID: appDelegate.sessionID!
            ]
            
            /* 2/3. Build the URL, Configure the request */
            let request = NSMutableURLRequest(URL: appDelegate.tmdbURLFromParameters(methodParameters, withPathExtension: "/account/\(appDelegate.userID!)/favorite/movies"))
            request.addValue("application/json", forHTTPHeaderField: "Accept")
            
            /* 4A. Make the request */
            let task = appDelegate.sharedSession.dataTaskWithRequest(request) { (data, response, error) in
                
                /* GUARD: Was there an error? */
                guard (error == nil) else {
                    print("There was an error with your request: \(error)")
                    return
                }
                
                /* GUARD: Did we get a successful 2XX response? */
                guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
                    print("Your request returned a status code other than 2xx!")
                    return
                }
                
                /* GUARD: Was there any data returned? */
                guard let data = data else {
                    print("No data was returned by the request!")
                    return
                }
                
                /* 5A. Parse the data */
                let parsedResult: AnyObject!
                do {
                    parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments) as? [String:AnyObject]
                } catch {
                    print("Could not parse the data as JSON: '\(data)'")
                    return
                }
                
                /* GUARD: Did TheMovieDB return an error? */
                if let _ = parsedResult[Constants.TMDBResponseKeys.StatusCode] as? Int {
                    print("TheMovieDB returned an error. See the '\(Constants.TMDBResponseKeys.StatusCode)' and '\(Constants.TMDBResponseKeys.StatusMessage)' in \(parsedResult)")
                    return
                }
                
                /* GUARD: Is the "results" key in parsedResult? */
                guard let results = parsedResult[Constants.TMDBResponseKeys.Results] as? [[String:AnyObject]] else {
                    print("Cannot find key '\(Constants.TMDBResponseKeys.Results)' in \(parsedResult)")
                    return
                }
                
                /* 6A. Use the data! */
                let myFavoritesMovies = Movie.moviesFromResults(results)
                self.isFavorite = false
                
                for movie in myFavoritesMovies {
                    if movie.id == self.selectedMovie!.id {
                        self.isFavorite = true
                    }
                }
                
                performUIUpdatesOnMain {
                    self.favoriteButton.tintColor = (self.isFavorite) ? UIColor.redColor() : UIColor.blackColor()
                }
            }
            
            /* 7A. Start the request */
            task.resume()
            
            /* TASK B: Get the poster image, then populate the image view */
            if let posterPath = selecteMovie.posterPath {
                
                /* 1B. Set the parameters */
                // There are none...
                
                /* 2B. Build the URL */
                let baseURL = NSURL(string: appDelegate.config.baseImageURLString)!
                let url = baseURL.URLByAppendingPathComponent("w342")!.URLByAppendingPathComponent(posterPath)
                
                /* 3B. Configure the request */
                let request = NSURLRequest(URL: url!)
                
                /* 4B. Make the request */
                let task = appDelegate.sharedSession.dataTaskWithRequest(request) { (data, response, error) in
                    
                    /* GUARD: Was there an error? */
                    guard (error == nil) else {
                        print("There was an error with your request: \(error)")
                        return
                    }
                    
                    /* GUARD: Did we get a successful 2XX response? */
                    guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
                        print("Your request returned a status code other than 2xx!")
                        return
                    }
                    
                    /* GUARD: Was there any data returned? */
                    guard let data = data else {
                        print("No data was returned by the request!")
                        return
                    }
                    
                    /* 5B. Parse the data */
                    // No need, the data is already raw image data.
                    
                    /* 6B. Use the data! */
                    if let image = UIImage(data: data) {
                        performUIUpdatesOnMain {
                            self.posterImageView!.image = image
                        }
                    } else {
                        print("Could not create image from \(data)")
                    }
                }
                
                /* 7B. Start the request */
                task.resume()
            }
        }
    }
    
    // MARK: Favorite Actions
    
    @IBAction func toggleFavorite(sender: AnyObject) {
        
        let postBody: NSData
        
        /* TASK: Add movie as favorite, then update favorite buttons */
        
        /* 1. Set the parameters */
        let requestHeaders = [Constants.TMDBHeaderKeys.ContentType: "\(Constants.ContenTypeValues.JSON);\(Constants.ContenTypeValues.Charset)"]
        
        let requestBody = [
            "media_type": "movie",
            "media_id": selectedMovie!.id,
            "favorite": !isFavorite
        ]
        
        let methodParameters = [
            Constants.TMDBParameterKeys.ApiKey: Constants.TMDBParameterValues.ApiKey,
            Constants.TMDBParameterKeys.SessionID: appDelegate.sessionID!
        ]
        
        /* 1.1 Serialize data for the request */
        func displayError(error: String) {
            print(error)
        }
        
        do {
            postBody = try NSJSONSerialization.dataWithJSONObject(requestBody, options: [])
        } catch {
            displayError("Could not create a JSON from: \(requestBody)")
            return
        }
        
        /* 2/3. Build the URL, Configure the request */
        let postRequest = NSMutableURLRequest(URL: appDelegate.tmdbURLFromParameters(methodParameters,
                                                                                     withPathExtension: "/account/\(appDelegate.userID!)/favorite"),
                                              cachePolicy: .UseProtocolCachePolicy,
                                              timeoutInterval: 10.0)
        
        /* 4. Make the request */
        postRequest.HTTPMethod = "POST"
        postRequest.allHTTPHeaderFields = requestHeaders
        postRequest.HTTPBody = postBody
        
        let dataTask = appDelegate.sharedSession.dataTaskWithRequest(postRequest) { (data, response, error) in
            /* GUARD: Was there an error? */
            guard (error == nil) else {
                displayError("Error: in your request: \(error)")
                return
            }
            
            /* GUARD: Did we get a successful 2XX response? */
            guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode
                where statusCode >= 200 && statusCode <= 299
                else {
                    displayError("Error: request status code returned other than 2xx!")
                    return
            }
            print("response: \n\(response)")
            
            /* GUARD: Was there any data returned? */
            guard let data = data else {
                displayError("Error: No data was returned by the request!")
                return
            }
            //URL: https://api.themoviedb.org/3/account/6418353/favorite?session_id=64a484b7c2189971af6fc5c1e36deaa69b90b570&api_key=7e98d32900beea3bf969312bb6b13a9e
            
            /* 5. Parse the data */
            let parsedResult: AnyObject!
            
            do {
                parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments) as? [String:AnyObject]
                print("toggleFavorite() parsedResult: \n\(parsedResult)")
            } catch {
                displayError("Could not parse the data as JSON: \(data)")
                return
            }
            
            /* 6. Use the data! */
            /* GUARD: Did TheMovieDB return an error? */
            guard let statusCodeFavorite = parsedResult[Constants.TMDBResponseKeys.StatusCode] as? Int  else  {
                displayError("TheMovieDB returned an error. See the '\(Constants.TMDBResponseKeys.StatusCode)' and '\(Constants.TMDBResponseKeys.StatusMessage)' in \(parsedResult)")
                return
            }
            
            self.isFavorite = statusCodeFavorite == 1 || statusCodeFavorite == 12 ? true : false
            
            /* If the favorite/unfavorite request completes, then use this code to update the UI... */
            performUIUpdatesOnMain {
                self.favoriteButton.tintColor = (self.isFavorite) ? UIColor.redColor() : UIColor.blackColor()
            }
        }
        /* 7. Start the request */
        dataTask.resume()
        
    }
}
