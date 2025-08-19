//SystemVerilog

//-----------------------------------------------------------------------------
// AddrDecoder
// 功能: 地址译码器，将输入地址addr译码为独热码onehot_out
//-----------------------------------------------------------------------------
module AddrDecoder #(parameter AW=4) (
    input  [AW-1:0] addr,
    output reg [(2**AW)-1:0] onehot_out
);
    integer i;
    always @* begin
        onehot_out = {(2**AW){1'b0}};
        for (i = 0; i < 2**AW; i = i + 1) begin
            if (addr == i)
                onehot_out[i] = 1'b1;
        end
    end
endmodule

//-----------------------------------------------------------------------------
// DataMux
// 功能: 根据独热码选择，将data_in扩展到对应data_out位宽
//-----------------------------------------------------------------------------
module DataMux #(parameter AW=4, DW=8) (
    input  [(2**AW)-1:0] onehot_sel,
    input  [DW-1:0]      data_in,
    output reg [(2**AW)*DW-1:0] data_out
);
    integer i;
    always @* begin
        data_out = {((2**AW)*DW){1'b0}};
        for (i = 0; i < 2**AW; i = i + 1) begin
            if (onehot_sel[i])
                data_out[(i*DW) +: DW] = data_in;
        end
    end
endmodule

//-----------------------------------------------------------------------------
// AddrDecMux (Top-level)
// 功能: 地址译码与数据多路分发顶层模块
//-----------------------------------------------------------------------------
module AddrDecMux #(parameter AW=4, DW=8) (
    input  [AW-1:0] addr,
    output [(2**AW)*DW-1:0] data_out,
    input  [DW-1:0] data_in
);
    wire [(2**AW)-1:0] onehot_sel;

    // 地址译码子模块
    AddrDecoder #(.AW(AW)) u_addr_decoder (
        .addr(addr),
        .onehot_out(onehot_sel)
    );

    // 数据多路分发子模块
    DataMux #(.AW(AW), .DW(DW)) u_data_mux (
        .onehot_sel(onehot_sel),
        .data_in(data_in),
        .data_out(data_out)
    );
endmodule