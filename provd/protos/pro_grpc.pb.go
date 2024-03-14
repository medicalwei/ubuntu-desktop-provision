// Code generated by protoc-gen-go-grpc. DO NOT EDIT.
// versions:
// - protoc-gen-go-grpc v1.3.0
// - protoc             v3.21.12
// source: protos/pro.proto

package proto

import (
	context "context"
	grpc "google.golang.org/grpc"
	codes "google.golang.org/grpc/codes"
	status "google.golang.org/grpc/status"
	emptypb "google.golang.org/protobuf/types/known/emptypb"
	wrapperspb "google.golang.org/protobuf/types/known/wrapperspb"
)

// This is a compile-time assertion to ensure that this generated file
// is compatible with the grpc package it is being compiled against.
// Requires gRPC-Go v1.32.0 or later.
const _ = grpc.SupportPackageIsVersion7

const (
	ProEnrolmentService_ProMagicAttach_FullMethodName = "/pro.ProEnrolmentService/ProMagicAttach"
	ProEnrolmentService_ProAttach_FullMethodName      = "/pro.ProEnrolmentService/ProAttach"
)

// ProEnrolmentServiceClient is the client API for ProEnrolmentService service.
//
// For semantics around ctx use and closing/ending streaming RPCs, please refer to https://pkg.go.dev/google.golang.org/grpc/?tab=doc#ClientConn.NewStream.
type ProEnrolmentServiceClient interface {
	ProMagicAttach(ctx context.Context, in *emptypb.Empty, opts ...grpc.CallOption) (ProEnrolmentService_ProMagicAttachClient, error)
	ProAttach(ctx context.Context, in *wrapperspb.StringValue, opts ...grpc.CallOption) (*emptypb.Empty, error)
}

type proEnrolmentServiceClient struct {
	cc grpc.ClientConnInterface
}

func NewProEnrolmentServiceClient(cc grpc.ClientConnInterface) ProEnrolmentServiceClient {
	return &proEnrolmentServiceClient{cc}
}

func (c *proEnrolmentServiceClient) ProMagicAttach(ctx context.Context, in *emptypb.Empty, opts ...grpc.CallOption) (ProEnrolmentService_ProMagicAttachClient, error) {
	stream, err := c.cc.NewStream(ctx, &ProEnrolmentService_ServiceDesc.Streams[0], ProEnrolmentService_ProMagicAttach_FullMethodName, opts...)
	if err != nil {
		return nil, err
	}
	x := &proEnrolmentServiceProMagicAttachClient{stream}
	if err := x.ClientStream.SendMsg(in); err != nil {
		return nil, err
	}
	if err := x.ClientStream.CloseSend(); err != nil {
		return nil, err
	}
	return x, nil
}

type ProEnrolmentService_ProMagicAttachClient interface {
	Recv() (*ProMagicAttachResponse, error)
	grpc.ClientStream
}

type proEnrolmentServiceProMagicAttachClient struct {
	grpc.ClientStream
}

func (x *proEnrolmentServiceProMagicAttachClient) Recv() (*ProMagicAttachResponse, error) {
	m := new(ProMagicAttachResponse)
	if err := x.ClientStream.RecvMsg(m); err != nil {
		return nil, err
	}
	return m, nil
}

func (c *proEnrolmentServiceClient) ProAttach(ctx context.Context, in *wrapperspb.StringValue, opts ...grpc.CallOption) (*emptypb.Empty, error) {
	out := new(emptypb.Empty)
	err := c.cc.Invoke(ctx, ProEnrolmentService_ProAttach_FullMethodName, in, out, opts...)
	if err != nil {
		return nil, err
	}
	return out, nil
}

// ProEnrolmentServiceServer is the server API for ProEnrolmentService service.
// All implementations must embed UnimplementedProEnrolmentServiceServer
// for forward compatibility
type ProEnrolmentServiceServer interface {
	ProMagicAttach(*emptypb.Empty, ProEnrolmentService_ProMagicAttachServer) error
	ProAttach(context.Context, *wrapperspb.StringValue) (*emptypb.Empty, error)
	mustEmbedUnimplementedProEnrolmentServiceServer()
}

// UnimplementedProEnrolmentServiceServer must be embedded to have forward compatible implementations.
type UnimplementedProEnrolmentServiceServer struct {
}

func (UnimplementedProEnrolmentServiceServer) ProMagicAttach(*emptypb.Empty, ProEnrolmentService_ProMagicAttachServer) error {
	return status.Errorf(codes.Unimplemented, "method ProMagicAttach not implemented")
}
func (UnimplementedProEnrolmentServiceServer) ProAttach(context.Context, *wrapperspb.StringValue) (*emptypb.Empty, error) {
	return nil, status.Errorf(codes.Unimplemented, "method ProAttach not implemented")
}
func (UnimplementedProEnrolmentServiceServer) mustEmbedUnimplementedProEnrolmentServiceServer() {}

// UnsafeProEnrolmentServiceServer may be embedded to opt out of forward compatibility for this service.
// Use of this interface is not recommended, as added methods to ProEnrolmentServiceServer will
// result in compilation errors.
type UnsafeProEnrolmentServiceServer interface {
	mustEmbedUnimplementedProEnrolmentServiceServer()
}

func RegisterProEnrolmentServiceServer(s grpc.ServiceRegistrar, srv ProEnrolmentServiceServer) {
	s.RegisterService(&ProEnrolmentService_ServiceDesc, srv)
}

func _ProEnrolmentService_ProMagicAttach_Handler(srv interface{}, stream grpc.ServerStream) error {
	m := new(emptypb.Empty)
	if err := stream.RecvMsg(m); err != nil {
		return err
	}
	return srv.(ProEnrolmentServiceServer).ProMagicAttach(m, &proEnrolmentServiceProMagicAttachServer{stream})
}

type ProEnrolmentService_ProMagicAttachServer interface {
	Send(*ProMagicAttachResponse) error
	grpc.ServerStream
}

type proEnrolmentServiceProMagicAttachServer struct {
	grpc.ServerStream
}

func (x *proEnrolmentServiceProMagicAttachServer) Send(m *ProMagicAttachResponse) error {
	return x.ServerStream.SendMsg(m)
}

func _ProEnrolmentService_ProAttach_Handler(srv interface{}, ctx context.Context, dec func(interface{}) error, interceptor grpc.UnaryServerInterceptor) (interface{}, error) {
	in := new(wrapperspb.StringValue)
	if err := dec(in); err != nil {
		return nil, err
	}
	if interceptor == nil {
		return srv.(ProEnrolmentServiceServer).ProAttach(ctx, in)
	}
	info := &grpc.UnaryServerInfo{
		Server:     srv,
		FullMethod: ProEnrolmentService_ProAttach_FullMethodName,
	}
	handler := func(ctx context.Context, req interface{}) (interface{}, error) {
		return srv.(ProEnrolmentServiceServer).ProAttach(ctx, req.(*wrapperspb.StringValue))
	}
	return interceptor(ctx, in, info, handler)
}

// ProEnrolmentService_ServiceDesc is the grpc.ServiceDesc for ProEnrolmentService service.
// It's only intended for direct use with grpc.RegisterService,
// and not to be introspected or modified (even as a copy)
var ProEnrolmentService_ServiceDesc = grpc.ServiceDesc{
	ServiceName: "pro.ProEnrolmentService",
	HandlerType: (*ProEnrolmentServiceServer)(nil),
	Methods: []grpc.MethodDesc{
		{
			MethodName: "ProAttach",
			Handler:    _ProEnrolmentService_ProAttach_Handler,
		},
	},
	Streams: []grpc.StreamDesc{
		{
			StreamName:    "ProMagicAttach",
			Handler:       _ProEnrolmentService_ProMagicAttach_Handler,
			ServerStreams: true,
		},
	},
	Metadata: "protos/pro.proto",
}
