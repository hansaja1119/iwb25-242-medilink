def preprocess_image(image):
    # Convert the image to grayscale
    gray_image = image.convert('L')
    
    # Apply thresholding to get a binary image
    binary_image = gray_image.point(lambda x: 0 if x < 128 else 255, '1')
    
    return binary_image

def resize_image(image, width):
    # Calculate the height based on the aspect ratio
    aspect_ratio = image.height / image.width
    height = int(aspect_ratio * width)
    
    # Resize the image
    resized_image = image.resize((width, height))
    
    return resized_image

def save_image(image, path):
    # Save the processed image to the specified path
    image.save(path)