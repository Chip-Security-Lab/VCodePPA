//SystemVerilog
module bitserial_crc(
    input wire clk,
    input wire rst,
    input wire bit_in,
    input wire bit_valid,
    output wire [7:0] crc8_out
);
    parameter CRC_POLY = 8'h07; // x^8 + x^2 + x + 1
    
    // 内部信号声明
    wire feedback;
    wire feedback_pipe;
    wire [7:0] crc_poly_masked;
    wire bit_valid_pipe;
    wire [7:0] crc_reg;
    
    // 实例化子模块
    feedback_calc u_feedback_calc(
        .crc_reg(crc_reg),
        .bit_in(bit_in),
        .feedback(feedback)
    );
    
    pipeline_reg u_pipeline_reg(
        .clk(clk),
        .rst(rst),
        .feedback(feedback),
        .bit_valid(bit_valid),
        .feedback_pipe(feedback_pipe),
        .bit_valid_pipe(bit_valid_pipe)
    );
    
    poly_mask u_poly_mask(
        .feedback_pipe(feedback_pipe),
        .crc_poly_masked(crc_poly_masked)
    );
    
    crc_reg_update u_crc_reg_update(
        .clk(clk),
        .rst(rst),
        .bit_valid_pipe(bit_valid_pipe),
        .crc_poly_masked(crc_poly_masked),
        .crc_reg(crc_reg)
    );
    
    // 向外部输出最终CRC结果
    assign crc8_out = crc_reg;
    
endmodule

// 反馈位计算模块
module feedback_calc(
    input wire [7:0] crc_reg,
    input wire bit_in,
    output wire feedback
);
    assign feedback = crc_reg[7] ^ bit_in;
endmodule

// 流水线寄存器模块
module pipeline_reg(
    input wire clk,
    input wire rst,
    input wire feedback,
    input wire bit_valid,
    output reg feedback_pipe,
    output reg bit_valid_pipe
);
    always @(posedge clk) begin
        if (rst) begin
            feedback_pipe <= 1'b0;
            bit_valid_pipe <= 1'b0;
        end else begin
            feedback_pipe <= feedback;
            bit_valid_pipe <= bit_valid;
        end
    end
endmodule

// 多项式掩码生成模块
module poly_mask(
    input wire feedback_pipe,
    output wire [7:0] crc_poly_masked
);
    parameter CRC_POLY = 8'h07;
    assign crc_poly_masked = feedback_pipe ? CRC_POLY : 8'h00;
endmodule

// CRC寄存器更新模块
module crc_reg_update(
    input wire clk,
    input wire rst,
    input wire bit_valid_pipe,
    input wire [7:0] crc_poly_masked,
    output reg [7:0] crc_reg
);
    always @(posedge clk) begin
        if (rst) begin
            crc_reg <= 8'h00;
        end else if (bit_valid_pipe) begin
            crc_reg <= {crc_reg[6:0], 1'b0} ^ crc_poly_masked;
        end
    end
endmodule