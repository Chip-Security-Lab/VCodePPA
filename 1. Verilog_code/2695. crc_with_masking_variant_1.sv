//SystemVerilog
// 子模块1: 数据掩码处理
module data_masker(
    input wire [7:0] data_in,
    input wire [7:0] mask,
    output reg [7:0] masked_data
);
    always @(*) begin
        masked_data = data_in & mask;
    end
endmodule

// 子模块2: CRC多项式选择
module poly_selector(
    input wire crc_msb,
    input wire data_lsb,
    input wire [7:0] poly,
    output wire [7:0] poly_mux
);
    wire poly_sel = crc_msb ^ data_lsb;
    assign poly_mux = poly_sel ? poly : 8'h00;
endmodule

// 子模块3: CRC计算核心
module crc_core(
    input wire clk,
    input wire rst,
    input wire [7:0] masked_data,
    input wire [7:0] poly_mux,
    output reg [7:0] crc
);
    wire [7:0] crc_shift = {crc[6:0], 1'b0};
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            crc <= 8'h00;
        end
        else begin
            crc <= crc_shift ^ poly_mux;
        end
    end
endmodule

// 子模块4: 状态控制器
module state_controller(
    input wire clk,
    input wire rst,
    input wire req,
    output reg busy,
    output reg ack
);
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            busy <= 1'b0;
            ack <= 1'b0;
        end
        else begin
            if (req && !busy) begin
                busy <= 1'b1;
                ack <= 1'b1;
            end
            else if (busy) begin
                ack <= 1'b0;
                if (!req) begin
                    busy <= 1'b0;
                end
            end
        end
    end
endmodule

// 顶层模块
module crc_with_masking(
    input wire clk,
    input wire rst,
    input wire [7:0] data,
    input wire [7:0] mask,
    input wire req,
    output wire ack,
    output wire [7:0] crc
);
    parameter [7:0] POLY = 8'h07;
    
    wire [7:0] masked_data;
    wire busy;
    wire crc_msb = crc[7];
    wire data_lsb = masked_data[0];
    wire [7:0] poly_mux;
    
    data_masker masker_inst(
        .data_in(data),
        .mask(mask),
        .masked_data(masked_data)
    );
    
    poly_selector poly_sel_inst(
        .crc_msb(crc_msb),
        .data_lsb(data_lsb),
        .poly(POLY),
        .poly_mux(poly_mux)
    );
    
    crc_core crc_inst(
        .clk(clk),
        .rst(rst),
        .masked_data(masked_data),
        .poly_mux(poly_mux),
        .crc(crc)
    );
    
    state_controller ctrl_inst(
        .clk(clk),
        .rst(rst),
        .req(req),
        .busy(busy),
        .ack(ack)
    );
endmodule