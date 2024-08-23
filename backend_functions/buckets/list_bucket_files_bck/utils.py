# Common image and video file extensions
IMAGE_EXTENSIONS = {'jpg', 'jpeg', 'png', 'gif', 'bmp', 'tiff', 'webp'}
VIDEO_EXTENSIONS = {'mp4', 'mkv', 'avi', 'mov', 'wmv', 'flv', 'webm', 'm4v'}

def validate_image(extension):
    return extension in IMAGE_EXTENSIONS

def validate_video(extension):
    return extension in VIDEO_EXTENSIONS
