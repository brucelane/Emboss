#include "cinder/ImageIo.h"
#include "cinder/app/AppNative.h"
#include "cinder/gl/gl.h"
#include "cinder/gl/GlslProg.h"
#include "cinder/gl/Texture.h"
#include "cinder/qtime/QuickTime.h"
#include "cinder/Text.h"
#include "cinder/Utilities.h"

using namespace ci;
using namespace ci::app;

using namespace std;

class EmbossApp : public AppNative {
public:
	void setup();
	void mouseDown( MouseEvent event );	
	void mouseMove( MouseEvent event );	
	void mouseDrag( MouseEvent event );	
	void update();
	void draw();
	void addFullScreenMovie( const fs::path &path );
	void fileDrop( FileDropEvent event );
	void keyDown( KeyEvent event );
private:
	gl::Texture		mTexture0;
	//gl::Texture		mTexture1;
	gl::Texture		mFrameTexture, mInfoTexture;

	Vec3i		    iResolution;           // viewport resolution (in pixels)
	Vec3i		    iChannelResolution;    
	float			iGlobalTime;           // shader playback time (in seconds)
	Vec3i			iMouse;                // mouse pixel coords. xy: current (if MLB down), zw: click
	gl::GlslProg	mShader;
	int				iEmboss;
	qtime::MovieGl				mMovie;
	bool			movieLoaded;
};
//full screen movie
void EmbossApp::addFullScreenMovie( const fs::path &path )
{
	console() << "Add FullScreen Movie" << std::endl;
	try 
	{
		/*textMask.setup( mRenderWidth, mRenderHeight );
		textMask.loadFullScreenMovieFile( moviePath );*/
		mMovie = qtime::MovieGl(path );
		mMovie.setLoop();
		mMovie.play();
		mMovie.setVolume( 0.0f );
		movieLoaded = true;
		//iEmboss = 0;
		// create a texture for showing some info about the movie
		TextLayout infoText;
		infoText.clear( ColorA( 0.2f, 0.2f, 0.2f, 0.5f ) );
		infoText.setColor( Color::white() );
		infoText.addCenteredLine( path.filename().string() );
		infoText.addLine( toString( mMovie.getWidth() ) + " x " + toString( mMovie.getHeight() ) + " pixels" );
		infoText.addLine( toString( mMovie.getDuration() ) + " seconds" );
		infoText.addLine( toString( mMovie.getNumFrames() ) + " frames" );
		infoText.addLine( toString( mMovie.getFramerate() ) + " fps" );
		infoText.setBorder( 4, 2 );
		mInfoTexture = gl::Texture( infoText.render( true ) );

	}
	catch( ... ) {
		console() << "Unable to load the movie." << std::endl;
		mMovie.reset();
		mInfoTexture.reset();
	}

	mFrameTexture.reset();
}
void EmbossApp::fileDrop( FileDropEvent event )
{
	addFullScreenMovie( event.getFile( 0 ) );
}
void EmbossApp::keyDown( KeyEvent event )
{
	if( event.getChar() == 'f' ) {
		setFullScreen( ! isFullScreen() );
	}
	else if( event.getChar() == '1' )
		mMovie.setRate( 0.5f );
	else if( event.getChar() == '2' )
		mMovie.setRate( 2 );
}
void EmbossApp::setup()
{
	movieLoaded = false;
	try 
	{
		iResolution = Vec3i( 1024, 768, 1 );
		iEmboss = 0;
		iGlobalTime = 1;
		iMouse = Vec3i( 512, 300, 1 );

		gl::Texture::Format format;
		format.setTargetRect();
		mTexture0 = gl::Texture(loadImage( loadAsset("emboss.jpg") ), format);

		// load the two textures
		//mTexture0 = gl::Texture( loadImage( loadAsset("emboss.jpg") ) );
		iChannelResolution = Vec3i( mTexture0.getWidth(),  mTexture0.getHeight(), 1);
		// load and compile the shader
		mShader = gl::GlslProg( loadAsset("Emboss_vert.glsl"), loadAsset("Emboss_frag.glsl") );
		//addFullScreenMovie();
	}
	catch( const std::exception &e ) 
	{
		// if anything went wrong, show it in the output window
		console() << e.what() << std::endl;
	}
}

void EmbossApp::mouseDown( MouseEvent event )
{
	iMouse =  Vec3i( event.getX(), 768 - event.getY(), 1 );
}
void EmbossApp::mouseDrag( MouseEvent event )
{
	iMouse =  Vec3i( event.getX(), 768 - event.getY(), 1 );
}
void EmbossApp::mouseMove( MouseEvent event )
{
	iMouse =  Vec3i( event.getX(), 768 - event.getY(), 1 );
}
void EmbossApp::update()
{
	if ( mMovie )
	{
		mFrameTexture = mMovie.getTexture();
	}
}

void EmbossApp::draw()
{
	// clear the window
	gl::clear();
	/*if ( mMovie )
	{
		gl::enableAlphaBlending();
		if( mFrameTexture ) 
		{
		Rectf centeredRect = Rectf( mFrameTexture.getBounds() ).getCenteredFit( getWindowBounds(), true );
		gl::draw( mFrameTexture, centeredRect  );
		}
		if( mInfoTexture )
		{
			glDisable( GL_TEXTURE_RECTANGLE_ARB );
			gl::draw( mInfoTexture, Vec2f( 20, getWindowHeight() - 20 - mInfoTexture.getHeight() ) );
		}
		gl::disableAlphaBlending();
	}	
	else
	{*/
	
		mShader.bind();
		mShader.uniform("iGlobalTime",iGlobalTime++);
		mShader.uniform("iResolution",iResolution);
		mShader.uniform("iMouse", iMouse);
		mShader.uniform("iEmboss", iEmboss);
		mShader.uniform("iChannel0", 0);
		mShader.uniform("iChannel1", 1);
		mShader.uniform("iChannelResolution", iChannelResolution);
		// enable the use of textures
		gl::enable( GL_TEXTURE_2D );

		if ( mMovie && mFrameTexture )
		{
			mFrameTexture.bind(0);
		}
		else
		{
			mTexture0.bind(0);
		}
		gl::drawSolidRect( Rectf( getWindowBounds() ), false );

		// unbind textures and shader
		mTexture0.unbind();
		mShader.unbind();
	
}

CINDER_APP_NATIVE( EmbossApp, RendererGl )
