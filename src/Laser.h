#ifndef LASER_H
#define LASER_H


#include "vdjVideo8.h"
#include <cmath> // for the function floor()
#include <stdio.h>
#include <d3d11.h>
#pragma comment(lib, "d3d11.lib")

#include <chrono>

using namespace std;


//////////////////////////////////////////////////////////////////////////
// Class definition
//////////////////////////////////////////////////////////////////////////
class CLaser : public IVdjPluginVideoFx8
{
public:
	CLaser();
	~CLaser();
	HRESULT VDJ_API OnLoad();
	HRESULT VDJ_API OnGetPluginInfo(TVdjPluginInfo8 *info);
	ULONG   VDJ_API Release();
	HRESULT VDJ_API OnParameter(int id);
	HRESULT VDJ_API OnGetParameterString(int id, char* outParam, int outParamSize);
	HRESULT VDJ_API OnDeviceInit();
	HRESULT VDJ_API OnDeviceClose();
	HRESULT VDJ_API OnDraw();
	HRESULT VDJ_API OnStart();
	HRESULT VDJ_API OnStop();
	HRESULT VDJ_API OnAudioSamples(float* buffer, int nb);

private:
	struct D3DXPOSITION
	{
		float x;
		float y;
		float z;
	};
	struct D3DXCOLOR
	{
	public:
		D3DXCOLOR() = default;
		D3DXCOLOR(FLOAT r, FLOAT g, FLOAT b, FLOAT a)
		{
			this->r = r;
			this->g = g;
			this->b = b;
			this->a = a;
		}

		operator FLOAT* ()
		{
			return &r;
		}

		FLOAT r, g, b, a;
	};
	struct D3DXTEXCOORD
	{
		float tu;
		float tv;
	};

	struct TLVERTEX
	{
		D3DXPOSITION position;
		D3DXCOLOR color;
		D3DXTEXCOORD texture;
	};

	struct InfoTexture2D
	{
		UINT Width;
		UINT Height;
		DXGI_FORMAT Format;
	};

	__declspec(align(16))
	struct PS_CONSTANTBUFFER
	{
		float FX_Time; // shader playback time
		float FX_SongPosBeats;
	};

	void OnResizeVideo();
	void OnSlider(int id);
	void DetectBeats();
	long long GetCurrentTimeMilliseconds();
	void setShaderPlaybackTime();
	HRESULT ReadResource(const WCHAR* resourceType, const WCHAR* resourceName, SIZE_T* size, LPVOID* data);

	HRESULT Initialize_D3D11(ID3D11Device* pDevice);
	void Release_D3D11();
	HRESULT Rendering_D3D11(ID3D11Device* pDevice, ID3D11DeviceContext* pDeviceContext, ID3D11RenderTargetView* pRenderTargetView, ID3D11ShaderResourceView* pTextureView, TVertex8* pVertices);
	HRESULT Create_PixelShader_D3D11(ID3D11Device* pDevice);
	HRESULT Create_PixelShaderFromResourceCSOFile_D3D11(ID3D11Device* pDevice, const WCHAR* resourceType, const WCHAR* resourceName);
	HRESULT Create_VertexBufferDynamic_D3D11(ID3D11Device* pDevice);
	HRESULT Update_VertexBufferDynamic_D3D11(ID3D11DeviceContext* ctx);
	HRESULT Update_Vertices_D3D11();
	HRESULT Create_BlendState_D3D11(ID3D11Device* pDevice);
	HRESULT Create_PSConstantBufferDynamic_D3D11(ID3D11Device* pDevice);
	HRESULT Update_PSConstantBufferDynamic_D3D11(ID3D11DeviceContext* ctx);
	HRESULT Update_PSConstantBufferData_D3D11();
	HRESULT GetInfoFromShaderResourceView(ID3D11ShaderResourceView* pShaderResourceView, InfoTexture2D* info);
	HRESULT GetInfoFromRenderTargetView(ID3D11RenderTargetView* pRenderTargetView, InfoTexture2D* info);

	
	ID3D11Device* pD3DDevice;
	ID3D11DeviceContext* pD3DDeviceContext;
	ID3D11RenderTargetView* pD3DRenderTargetView;
	ID3D11Buffer* pNewVertexBuffer;
	ID3D11PixelShader* pPixelShader;
	ID3D11BlendState* pBlendState;
	ID3D11Buffer* pPSConstantBuffer;

	PS_CONSTANTBUFFER m_PSConstantBufferData;
	
	TLVERTEX pNewVertices[6];
	UINT m_VertexCount;
	bool m_DirectX_On;
	int m_WidthOnDeviceInit;
	int m_HeightOnDeviceInit;
	int m_Width;
	int m_Height;
	float m_SliderValue[1];
	float m_alpha;
	long long m_TimeInit;
	float m_Time;

	typedef enum _ID_Interface
	{
		ID_INIT,
		ID_SLIDER_1,
	} ID_Interface;

	
	#ifndef SQ
	#define SQ(x) (x * x)
	#endif

	#ifndef SAFE_RELEASE
	#define SAFE_RELEASE(x) { if (x!=nullptr) { x->Release(); x=nullptr; } }
	#endif

};

#endif
