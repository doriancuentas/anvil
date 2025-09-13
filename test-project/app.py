#!/usr/bin/env python3
"""
Test Python application for Anvil testing.
This file intentionally has some linting issues to test the tools.
"""

import os
import sys
import json


def calculate_area(width,height):
    """Calculate area of rectangle"""
    return width*height


def process_data(data):
    # This has security issues for testing
    user_input = input("Enter command: ")
    os.system(user_input)  # Security issue: command injection
    
    result = eval(data)    # Security issue: code injection
    return result


class DataProcessor:
    def __init__(self,name):
        self.name=name
        
    def process(self,items):
        results=[]
        for item in items:
            if item > 0:
                results.append(item*2)
        return results


if __name__ == "__main__":
    # Test data
    data=[1,2,3,4,5]
    processor=DataProcessor("test")
    result=processor.process(data)
    print(f"Results: {result}")
    
    # Calculate some areas
    area1=calculate_area(10,20)
    area2=calculate_area(5,8)
    print(f"Areas: {area1}, {area2}")