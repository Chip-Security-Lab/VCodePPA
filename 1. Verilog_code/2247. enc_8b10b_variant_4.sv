//SystemVerilog
module enc_8b10b #(parameter K=0) (
    input [7:0] din,
    input rd_in,
    output [9:0] dout,
    output rd_out
);
    
    // 编码器数据处理模块输出信号
    wire [9:0] encoded_data;
    wire [5:0] disp_value;
    wire update_rd;
    
    // 实例化编码逻辑处理模块
    enc_8b10b_core #(.K(K)) encoder_core (
        .din(din),
        .encoded_data(encoded_data),
        .disp_value(disp_value),
        .update_rd(update_rd)
    );
    
    // 实例化色散处理模块
    disparity_handler disp_handler (
        .encoded_data(encoded_data),
        .disp_value(disp_value),
        .update_rd(update_rd),
        .rd_in(rd_in),
        .dout(dout),
        .rd_out(rd_out)
    );
    
endmodule

// 核心编码逻辑模块
module enc_8b10b_core #(parameter K=0) (
    input [7:0] din,
    output reg [9:0] encoded_data,
    output reg [5:0] disp_value,
    output reg update_rd
);
    
    // 编码映射表逻辑
    always @(*) begin
        case({K, din})
            9'b1_00011100: begin
                encoded_data = 10'b0011111010;
                disp_value = 6'd0;
                update_rd = 1'b1;
            end
            9'b0_10101010: begin
                encoded_data = 10'b1010010111;
                disp_value = 6'd2;
                update_rd = 1'b0;
            end
            9'b0_00000000: begin
                encoded_data = 10'b0101010101;
                disp_value = 6'd0;
                update_rd = 1'b0;
            end
            9'b0_11111111: begin
                encoded_data = 10'b1010101010;
                disp_value = 6'd0;
                update_rd = 1'b0;
            end
            default: begin
                encoded_data = 10'b0101010101;
                disp_value = 6'd0;
                update_rd = 1'b0;
            end
        endcase
    end
    
endmodule

// 色散处理模块
module disparity_handler (
    input [9:0] encoded_data,
    input [5:0] disp_value,
    input update_rd,
    input rd_in,
    output [9:0] dout,
    output reg rd_out
);
    
    // 色散计算连线
    wire [5:0] disparity;
    
    // 计算色散值
    assign disparity = disp_value;
    
    // 输出数据直接连通
    assign dout = encoded_data;
    
    // 运行差异输出逻辑
    always @(*) begin
        if (update_rd) begin
            rd_out = (rd_in <= 0);
        end else if (disp_value != 0) begin
            rd_out = rd_in + disparity;
        end else begin
            rd_out = rd_in;
        end
    end
    
endmodule