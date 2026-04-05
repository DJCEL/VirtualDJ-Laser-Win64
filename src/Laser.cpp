#include "Laser.h"


//------------------------------------------------------------------------------------------
CLazer::CLaser()
{
	pD3DDevice = nullptr; 
	pD3DDeviceContext = nullptr;
	pNewVertexBuffer = nullptr;
	pPixelShader = nullptr;
	pD3DRenderTargetView = nullptr;
	pBlendState = nullptr;
	pPSConstantBuffer = nullptr;
	ZeroMemory(pNewVertices, 6 * sizeof(TVertex8));
	ZeroMemory(m_SliderValue, 1 * sizeof(float));
	m_PSConstantBufferData = {};
	m_DirectX_On = false;
	m_Width = 0;
	m_Height = 0;
	m_VertexCount = 0;
	m_alpha = 1.0f;
	m_Time = 0.0f;
	m_TimeInit = 0;
}
//------------------------------------------------------------------------------------------
CLazer::~CLaser()
{

}
//------------------------------------------------------------------------------------------
HRESULT VDJ_API CLazer::OnLoad()
{
	HRESULT hr = S_FALSE;

	hr = DeclareParameterSlider(&m_SliderValue[0], ID_SLIDER_1, "Wet/Dry", "W/D", 1.0f);
	
	OnParameter(ID_INIT);
	return S_OK;
}
//------------------------------------------------------------------------------------------
HRESULT VDJ_API CLazer::OnGetPluginInfo(TVdjPluginInfo8 *info)
{
	info->Author = "djcel";
	info->PluginName = "Lazer";
	info->Description = "It emulates a lazer.";
	info->Flags = 0x00; // VDJFLAG_VIDEO_OVERLAY // VDJFLAG_VIDEO_OUTPUTRESOLUTION | VDJFLAG_VIDEO_OUTPUTASPECTRATIO;
	info->Version = "1.0 (64-bit)";

	return S_OK;
}
//------------------------------------------------------------------------------------------
ULONG VDJ_API CLazer::Release()
{
	delete this;
	return 0;
}
//------------------------------------------------------------------------------------------
HRESULT VDJ_API CLazer::OnParameter(int id)
{
	if (id == ID_INIT)
	{
		for (int i = 1; i <= 1; i++) OnSlider(i);
	}
	else
	{
		OnSlider(id);
	}
		
	return S_OK;
}
//------------------------------------------------------------------------------------------
void CLazer::OnSlider(int id)
{
	switch (id)
	{
		case ID_SLIDER_1:
			m_alpha = m_SliderValue[0];
			break;
	}
}
//-------------------------------------------------------------------------------------------
HRESULT VDJ_API CLazer::OnGetParameterString(int id, char* outParam, int outParamSize)
{
	switch (id)
	{
		case ID_SLIDER_1:
			sprintf_s(outParam, outParamSize, "%.0f%%", m_alpha * 100);
			break;
	}

	return S_OK;
}
//-------------------------------------------------------------------------------------------
HRESULT VDJ_API CLazer::OnDeviceInit()
{
	HRESULT hr = S_FALSE;

	m_DirectX_On = true;
	m_Width = width;
	m_Height = height;

	hr = GetDevice(VdjVideoEngineDirectX11, (void**)  &pD3DDevice);
	if(hr!=S_OK || pD3DDevice==NULL) return E_FAIL;

	hr = Initialize_D3D11(pD3DDevice);

	return S_OK;
}
//-------------------------------------------------------------------------------------------
HRESULT VDJ_API CLazer::OnDeviceClose()
{
	Release_D3D11();
	SAFE_RELEASE(pD3DRenderTargetView);
	SAFE_RELEASE(pD3DDeviceContext);
	m_DirectX_On = false;
	
	return S_OK;
}
//-------------------------------------------------------------------------------------------
HRESULT VDJ_API CLazer::OnStart() 
{
	m_TimeInit = GetCurrentTimeMilliseconds();

	return S_OK;
}
//-------------------------------------------------------------------------------------------
HRESULT VDJ_API CLazer::OnStop() 
{
	m_Time = 0.0f;
	m_TimeInit = 0;

	return S_OK;
}
//-------------------------------------------------------------------------------------------
HRESULT VDJ_API CLazer::OnDraw()
{
	HRESULT hr = S_FALSE;
	ID3D11ShaderResourceView *pTexture = nullptr;
	TVertex8* vertices = nullptr;

	setShaderPlaybackTime();

	if (width != m_Width || height != m_Height)
	{
		OnResizeVideo();
	}

	if (!pD3DDevice) return S_FALSE;

	pD3DDevice->GetImmediateContext(&pD3DDeviceContext);
	if (!pD3DDeviceContext) return S_FALSE;

	pD3DDeviceContext->OMGetRenderTargets(1, &pD3DRenderTargetView, nullptr);
	if (!pD3DRenderTargetView) return S_FALSE;

	// We get current texture and vertices
	hr = GetTexture(VdjVideoEngineDirectX11, (void**)&pTexture, &vertices);
	if (hr != S_OK) return S_FALSE;

	hr = Rendering_D3D11(pD3DDevice, pD3DDeviceContext, pD3DRenderTargetView, pTexture, vertices);
	if (hr != S_OK) return S_FALSE;

	return S_OK;
}
//-----------------------------------------------------------------------
HRESULT VDJ_API CLazer::OnAudioSamples(float* buffer, int nb)
{ 
	#ifdef USE_FFT
		int FFT_SIZE = 512; // Size of the FFT (must be a power of 2)
		ComputeFFT(buffer, nb, FFT_SIZE);
		return S_OK; 
	#else
		return E_NOTIMPL;
	#endif
}
//-----------------------------------------------------------------------
long long CLazer::GetCurrentTimeMilliseconds()
{
	std::chrono::time_point time = std::chrono::system_clock::now();
	std::chrono::duration since_epoch = time.time_since_epoch();
	long long milliseconds = std::chrono::duration_cast<std::chrono::milliseconds>(since_epoch).count();

	return milliseconds;
}
//-----------------------------------------------------------------------
void CLazer::setShaderPlaybackTime()
{
	long long TimeNow = GetCurrentTimeMilliseconds();

	m_Time = (TimeNow - m_TimeInit) / 1000.0f;
}
//-----------------------------------------------------------------------
void CLazer::OnResizeVideo()
{
	m_Width = width;
	m_Height = height;
}
//-----------------------------------------------------------------------
HRESULT CLazer::Initialize_D3D11(ID3D11Device* pDevice)
{
	HRESULT hr = S_FALSE;

	hr = Create_VertexBufferDynamic_D3D11(pDevice);
	if (hr != S_OK) return S_FALSE;

	hr = Create_PixelShader_D3D11(pDevice);
	if (hr != S_OK) return S_FALSE;

	hr = Create_BlendState_D3D11(pDevice);
	if (hr != S_OK) return S_FALSE;

	hr = Create_PSConstantBufferDynamic_D3D11(pDevice);
	if (hr != S_OK) return S_FALSE;

	return S_OK;
}
//-----------------------------------------------------------------------
void CLazer::Release_D3D11()
{
	SAFE_RELEASE(pNewVertexBuffer);
	SAFE_RELEASE(pPixelShader);
	SAFE_RELEASE(pBlendState);
	SAFE_RELEASE(pPSConstantBuffer);
}
// -----------------------------------------------------------------------
HRESULT CLazer::Rendering_D3D11(ID3D11Device* pDevice, ID3D11DeviceContext* pDeviceContext, ID3D11RenderTargetView* pRenderTargetView, ID3D11ShaderResourceView* pTextureView, TVertex8* pVertices)
{
	HRESULT hr = S_FALSE;

#ifdef _DEBUG
	InfoTexture2D InfoRTV = {};
	InfoTexture2D InfoSRV = {};
	hr = GetInfoFromRenderTargetView(pRenderTargetView, &InfoRTV);
	hr = GetInfoFromShaderResourceView(pTextureView, &InfoSRV);
#endif

	hr = DrawDeck();
	if (hr != S_OK) return S_FALSE;


	if (pRenderTargetView)
	{
		FLOAT backgroundColor[4] = { 0.0f, 0.0f , 0.0f , 1.0f };
		//pDeviceContext->ClearRenderTargetView(pRenderTargetView, backgroundColor);
		//pDeviceContext->OMSetRenderTargets(1, &pRenderTargetView, nullptr);
	}

	hr = Update_VertexBufferDynamic_D3D11(pDeviceContext);
	if (hr != S_OK) return S_FALSE;

	hr = Update_PSConstantBufferDynamic_D3D11(pDeviceContext);
	if (hr != S_OK) return S_FALSE;

	
	if (pPixelShader)
	{
		pDeviceContext->PSSetShader(pPixelShader, nullptr, 0);
	}

	if (pPSConstantBuffer)
	{
		pDeviceContext->PSSetConstantBuffers(0, 1, &pPSConstantBuffer);
	}
	
	if (pTextureView)
	{
		pDeviceContext->PSSetShaderResources(0, 1, &pTextureView);
	}

	if (pBlendState)
	{
		//pDeviceContext->OMSetBlendState(pBlendState, nullptr, 0xFFFFFFFF);
	}
	
	if (pNewVertexBuffer)
	{
		UINT m_VertexStride = sizeof(TLVERTEX);
		UINT m_VertexOffset = 0;
		pDeviceContext->IASetPrimitiveTopology(D3D11_PRIMITIVE_TOPOLOGY_TRIANGLELIST);
		pDeviceContext->IASetVertexBuffers(0, 1, &pNewVertexBuffer, &m_VertexStride, &m_VertexOffset);
	}
	
	pDeviceContext->Draw(m_VertexCount, 0);
	
	return S_OK;
}
// ---------------------------------------------------------------------- -
HRESULT CLazer::Create_VertexBufferDynamic_D3D11(ID3D11Device* pDevice)
{
	HRESULT hr = S_FALSE;

	if (!pDevice) return S_FALSE;

	// Set the number of vertices in the vertex array.
	m_VertexCount = 6; // = ARRAYSIZE(pNewVertices);
	
	// Fill in a buffer description.
	D3D11_BUFFER_DESC VertexBufferDesc;
	ZeroMemory(&VertexBufferDesc, sizeof(VertexBufferDesc));
	VertexBufferDesc.Usage = D3D11_USAGE_DYNAMIC;   // CPU_Access=Write_Only & GPU_Access=Read_Only
	VertexBufferDesc.ByteWidth = sizeof(TLVERTEX) * m_VertexCount;
	VertexBufferDesc.BindFlags = D3D11_BIND_VERTEX_BUFFER; //D3D11_BIND_INDEX_BUFFER
	VertexBufferDesc.CPUAccessFlags = D3D11_CPU_ACCESS_WRITE; // Allow CPU to write in buffer
	VertexBufferDesc.MiscFlags = 0;

	hr = pDevice->CreateBuffer(&VertexBufferDesc, NULL, &pNewVertexBuffer);
	if (hr != S_OK || !pNewVertexBuffer) return S_FALSE;

	return S_OK;
}
//-----------------------------------------------------------------------
HRESULT CLazer::Update_VertexBufferDynamic_D3D11(ID3D11DeviceContext* ctx)
{
	HRESULT hr = S_FALSE;

	if (!ctx) return S_FALSE;
	if (!pNewVertexBuffer) return S_FALSE;

	D3D11_MAPPED_SUBRESOURCE MappedSubResource;
	ZeroMemory(&MappedSubResource, sizeof(D3D11_MAPPED_SUBRESOURCE));


	hr = ctx->Map(pNewVertexBuffer, NULL, D3D11_MAP_WRITE_DISCARD, 0, &MappedSubResource);
	if (hr != S_OK) return S_FALSE;

	hr = Update_Vertices_D3D11();

	memcpy(MappedSubResource.pData, pNewVertices, m_VertexCount * sizeof(TLVERTEX));

	ctx->Unmap(pNewVertexBuffer, NULL);

	return S_OK;
}
//-----------------------------------------------------------------------
HRESULT CLazer::Update_Vertices_D3D11()
{
	float frameWidth = (float) m_Width;
	float frameHeight = (float) m_Height;

	D3DXPOSITION P1 = { 0.0f, 0.0f, 0.0f }, // Top Left
		P2 = { 0.0f, frameHeight, 0.0f }, // Bottom Left
		P3 = { frameWidth, 0.0f, 0.0f }, // Top Right
		P4 = { frameWidth, frameHeight, 0.0f }; // Bottom Right
	D3DXCOLOR color_vertex = D3DXCOLOR(1.0f, 1.0f, 1.0f, m_alpha); // White color with alpha layer
	D3DXTEXCOORD T1 = { 0.0f , 0.0f }, T2 = { 0.0f , 1.0f }, T3 = { 1.0f , 0.0f }, T4 = { 1.0f , 1.0f };

	// Triangle n°1 (Bottom Right)
	pNewVertices[0] = { P3 , color_vertex , T3 };
	pNewVertices[1] = { P4 , color_vertex , T4 };
	pNewVertices[2] = { P2 , color_vertex , T2 };

	// Triangle n°2 (Top Left)
	pNewVertices[3] = { P2 , color_vertex , T2 };
	pNewVertices[4] = { P1 , color_vertex , T1 };
	pNewVertices[5] = { P3 , color_vertex , T3 };

	return S_OK;
}
//-----------------------------------------------------------------------
HRESULT CLazer::Create_PixelShader_D3D11(ID3D11Device* pDevice)
{
	HRESULT hr = S_FALSE;

	const WCHAR* resourceName = L"LAZER_CSO";
	const WCHAR* resourceType = RT_RCDATA;
	hr = Create_PixelShaderFromResourceCSOFile_D3D11(pDevice, resourceType, resourceName);

	return hr;
}
//-----------------------------------------------------------------------
HRESULT CLazer::Create_PixelShaderFromResourceCSOFile_D3D11(ID3D11Device* pDevice, const WCHAR* resourceType, const WCHAR* resourceName)
{
	HRESULT hr = S_FALSE;

	void* pShaderBytecode = nullptr;
	SIZE_T BytecodeLength = 0;

	hr = ReadResource(resourceType, resourceName, &BytecodeLength, &pShaderBytecode);
	if (hr != S_OK) return S_FALSE;
	

	SAFE_RELEASE(pPixelShader);

	hr = pDevice->CreatePixelShader(pShaderBytecode, BytecodeLength, nullptr, &pPixelShader);

	return hr;
}
//-----------------------------------------------------------------------
HRESULT CLazer::ReadResource(const WCHAR* resourceType, const WCHAR* resourceName, SIZE_T* size, LPVOID* data)
{
	HRESULT hr = S_FALSE;

	HRSRC rc = FindResource(hInstance, resourceName, resourceType);
	if (!rc) return S_FALSE;

	HGLOBAL rcData = LoadResource(hInstance, rc);
	if (!rcData) return S_FALSE;

	*size = (SIZE_T)SizeofResource(hInstance, rc);
	if (*size == 0) return S_FALSE;

	*data = LockResource(rcData);
	if (*data == nullptr) return S_FALSE;

	return S_OK;
}
//-----------------------------------------------------------------------
HRESULT CLazer::Create_BlendState_D3D11(ID3D11Device* pDevice)
{
	HRESULT hr = S_FALSE;

	D3D11_RENDER_TARGET_BLEND_DESC RenderTargetBlendDesc;
	ZeroMemory(&RenderTargetBlendDesc, sizeof(D3D11_RENDER_TARGET_BLEND_DESC));
	RenderTargetBlendDesc.BlendEnable = TRUE;
	RenderTargetBlendDesc.SrcBlend = D3D11_BLEND_SRC_COLOR; // The data source is color data (RGB) from a pixel shader. No pre-blend operation.
	RenderTargetBlendDesc.DestBlend = D3D11_BLEND_DEST_COLOR; // The data source is color data from a rendertarget. No pre-blend operation.
	RenderTargetBlendDesc.BlendOp = D3D11_BLEND_OP_ADD;
	RenderTargetBlendDesc.SrcBlendAlpha = D3D11_BLEND_SRC_ALPHA; // The data source is alpha data from a pixel shader. No pre-blend operation.
	RenderTargetBlendDesc.DestBlendAlpha = D3D11_BLEND_DEST_ALPHA; // The data source is alpha data from a rendertarget. No pre-blend operation. 
	RenderTargetBlendDesc.BlendOpAlpha = D3D11_BLEND_OP_ADD;
	RenderTargetBlendDesc.RenderTargetWriteMask = D3D11_COLOR_WRITE_ENABLE_ALPHA; // D3D11_COLOR_WRITE_ENABLE_ALL


	D3D11_BLEND_DESC BlendStateDesc;
	ZeroMemory(&BlendStateDesc, sizeof(D3D11_BLEND_DESC));
	BlendStateDesc.AlphaToCoverageEnable = FALSE;
	BlendStateDesc.IndependentBlendEnable = FALSE;
	BlendStateDesc.RenderTarget[0] = RenderTargetBlendDesc;

	hr = pDevice->CreateBlendState(&BlendStateDesc, &pBlendState);

	return hr;
}
//-----------------------------------------------------------------------
HRESULT CLazer::Create_PSConstantBufferDynamic_D3D11(ID3D11Device* pDevice)
{
	HRESULT hr = S_FALSE;

	if (!pDevice) return E_FAIL;

	UINT SIZEOF_PS_CONSTANTBUFFER = sizeof(PS_CONSTANTBUFFER);
	UINT CB_BYTEWIDTH = SIZEOF_PS_CONSTANTBUFFER + 0xf & 0xfffffff0;

	D3D11_BUFFER_DESC ConstantBufferDesc = {};
	ConstantBufferDesc.Usage = D3D11_USAGE_DYNAMIC;  // CPU_Access=Write_Only & GPU_Access=Read_Only
	ConstantBufferDesc.ByteWidth = CB_BYTEWIDTH;
	ConstantBufferDesc.BindFlags = D3D11_BIND_CONSTANT_BUFFER;
	ConstantBufferDesc.CPUAccessFlags = D3D11_CPU_ACCESS_WRITE;  // Allow CPU to write in buffer
	ConstantBufferDesc.MiscFlags = 0;

	// Create the constant buffer to send to the cbuffer in hlsl file
	hr = pDevice->CreateBuffer(&ConstantBufferDesc, nullptr, &pPSConstantBuffer);
	if (hr != S_OK || !pPSConstantBuffer) return S_FALSE;

	return hr;
}
//-----------------------------------------------------------------------
HRESULT CLazer::Update_PSConstantBufferDynamic_D3D11(ID3D11DeviceContext* ctx)
{
	HRESULT hr = S_FALSE;

	if (!ctx) return S_FALSE;
	if (!pPSConstantBuffer) return S_FALSE;

	hr = Update_PSConstantBufferData_D3D11();

	D3D11_MAPPED_SUBRESOURCE MappedSubResource;
	ZeroMemory(&MappedSubResource, sizeof(D3D11_MAPPED_SUBRESOURCE));

	hr = ctx->Map(pPSConstantBuffer, 0, D3D11_MAP_WRITE_DISCARD, 0, &MappedSubResource);
	if (hr != S_OK) return S_FALSE;

	memcpy(MappedSubResource.pData, &m_PSConstantBufferData, sizeof(PS_CONSTANTBUFFER));

	ctx->Unmap(pPSConstantBuffer, 0);

	return S_OK;
}
//-----------------------------------------------------------------------
HRESULT CLazer::Update_PSConstantBufferData_D3D11()
{
	m_PSConstantBufferData.FX_Time = float(m_Time);
	m_PSConstantBufferData.FX_SongPosBeats = (SongPosBeats < 0) ? 0.0f : float(SongPosBeats);

	return S_OK;
}
//-----------------------------------------------------------------------
HRESULT CLazer::GetInfoFromShaderResourceView(ID3D11ShaderResourceView* pShaderResourceView, InfoTexture2D* info)
{
	HRESULT hr = S_FALSE;

	D3D11_SHADER_RESOURCE_VIEW_DESC viewDesc;
	ZeroMemory(&viewDesc, sizeof(D3D11_SHADER_RESOURCE_VIEW_DESC));

	pShaderResourceView->GetDesc(&viewDesc);

	DXGI_FORMAT ViewFormat = viewDesc.Format;
	D3D11_SRV_DIMENSION ViewDimension = viewDesc.ViewDimension;

	ID3D11Resource* pResource = nullptr;
	pShaderResourceView->GetResource(&pResource);
	if (!pResource) return S_FALSE;

	if (ViewDimension == D3D11_SRV_DIMENSION_TEXTURE2D)
	{
		ID3D11Texture2D* pTexture = nullptr;
		hr = pResource->QueryInterface(__uuidof(ID3D11Texture2D), (void**)&pTexture);
		if (hr != S_OK || !pTexture) return S_FALSE;

		D3D11_TEXTURE2D_DESC textureDesc;
		ZeroMemory(&textureDesc, sizeof(D3D11_TEXTURE2D_DESC));

		pTexture->GetDesc(&textureDesc);

		info->Format = textureDesc.Format;
		info->Width = textureDesc.Width;
		info->Height = textureDesc.Height;

		SAFE_RELEASE(pTexture);
	}

	SAFE_RELEASE(pResource);

	return S_OK;
}
//-----------------------------------------------------------------------
HRESULT CLazer::GetInfoFromRenderTargetView(ID3D11RenderTargetView* pRenderTargetView, InfoTexture2D* info)
{
	HRESULT hr = S_FALSE;

	D3D11_RENDER_TARGET_VIEW_DESC viewDesc;
	ZeroMemory(&viewDesc, sizeof(D3D11_RENDER_TARGET_VIEW_DESC));

	pRenderTargetView->GetDesc(&viewDesc);

	DXGI_FORMAT ViewFormat = viewDesc.Format;
	D3D11_RTV_DIMENSION ViewDimension = viewDesc.ViewDimension;

	ID3D11Resource* pResource = nullptr;
	pRenderTargetView->GetResource(&pResource);
	if (!pResource) return S_FALSE;

	if (ViewDimension == D3D11_RTV_DIMENSION_TEXTURE2D)
	{
		ID3D11Texture2D* pTexture = nullptr;
		hr = pResource->QueryInterface(__uuidof(ID3D11Texture2D), (void**)&pTexture);
		if (hr != S_OK || !pTexture) return S_FALSE;

		D3D11_TEXTURE2D_DESC textureDesc;
		ZeroMemory(&textureDesc, sizeof(D3D11_TEXTURE2D_DESC));

		pTexture->GetDesc(&textureDesc);

		info->Format = textureDesc.Format;
		info->Width = textureDesc.Width;
		info->Height = textureDesc.Height;

		SAFE_RELEASE(pTexture);
	}

	SAFE_RELEASE(pResource);

	return S_OK;
}
