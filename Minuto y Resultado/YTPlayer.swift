//
//  YTPlayer.swift
//  90 Min
//
//  Created by Victor Manuel del Rio Garcia on 2/12/22.
//
import Foundation
import SwiftUI
import WebKit


struct YoutubeView: UIViewRepresentable{
    var videoID:String
    
    func makeUIView(context:Context)-> WKWebView{
        return WKWebView()
    }
    func updateUIView(_ uiView:WKWebView, context: Context){
        guard let youtubeURL = URL(string: "https://www.youtube.com/embed/\(videoID)") else {return}
        uiView.scrollView.isScrollEnabled=false
        uiView.load(URLRequest(url:youtubeURL))
        
    }
}



