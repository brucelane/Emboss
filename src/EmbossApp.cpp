#include "cinder/ImageIo.h"
#include "cinder/app/AppNative.h"
#include "cinder/gl/gl.h"
#include "cinder/gl/GlslProg.h"
#include "cinder/gl/Texture.h"

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
  private:
	gl::Texture		mTexture0;
	Vec3i		    iResolution;           // viewport resolution (in pixels)
	Vec3i		    iChannelResolution;    
	float			iGlobalTime;           // shader playback time (in seconds)
	Vec3i			iMouse;                // mouse pixel coords. xy: current (if MLB down), zw: click
	gl::GlslProg	mShader;
	int				iEmboss;
};

void EmbossApp::setup()
{
	try {
		iResolution = Vec3i( 1024, 768, 1 );
		iEmboss = 1;
		iGlobalTime = 1;
		iMouse = Vec3i( 512, 300, 1 );
		// load the two textures
		mTexture0 = gl::Texture( loadImage( loadAsset("emboss.jpg") ) );
		iChannelResolution = Vec3i( mTexture0.getWidth(),  mTexture0.getHeight(), 1);
		// load and compile the shader
		mShader = gl::GlslProg( loadAsset("Emboss_vert.glsl"), loadAsset("Emboss_frag.glsl") );
	}
	catch( const std::exception &e ) {
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
}

void EmbossApp::draw()
{
	// clear the window
	gl::clear();

	mShader.bind();
	mShader.uniform("iGlobalTime",iGlobalTime++);
	mShader.uniform("iResolution",iResolution);
	mShader.uniform("iMouse", iMouse);
	mShader.uniform("iEmboss", iEmboss);
	mShader.uniform("iChannel0", 0);
	mShader.uniform("iChannelResolution", iChannelResolution);
	// enable the use of textures
	gl::enable( GL_TEXTURE_2D );

	mTexture0.bind(0);

	gl::drawSolidRect( Rectf( getWindowBounds() ), false );

	// unbind textures and shader
	mTexture0.unbind();
	mShader.unbind();
}

CINDER_APP_NATIVE( EmbossApp, RendererGl )
