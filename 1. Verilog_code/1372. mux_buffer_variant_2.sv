//SystemVerilog
module mux_buffer (
    input wire clk,
    input wire rst_n,  // 添加复位信号
    input wire [1:0] select,
    input wire [7:0] data_a, data_b, data_c, data_d,
    input wire write_en,
    input wire valid_in,  // 输入有效信号
    output wire ready_out, // 输出就绪信号
    output reg [7:0] data_out,
    output reg valid_out   // 输出有效信号
);
    // Stage 1: Input registers and decode
    reg [7:0] data_a_stage1, data_b_stage1, data_c_stage1, data_d_stage1;
    reg [1:0] select_stage1;
    reg write_en_stage1;
    reg valid_stage1;
    
    // Stage 2: Memory access and output preparation
    reg [7:0] buffers [0:3];
    reg [7:0] data_selected_stage2;
    reg valid_stage2;
    
    // Pipeline control
    assign ready_out = 1'b1; // 本设计总是就绪接收数据
    
    // Stage 1: Register inputs
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_a_stage1 <= 8'h0;
            data_b_stage1 <= 8'h0;
            data_c_stage1 <= 8'h0;
            data_d_stage1 <= 8'h0;
            select_stage1 <= 2'b00;
            write_en_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
        end
        else begin
            data_a_stage1 <= data_a;
            data_b_stage1 <= data_b;
            data_c_stage1 <= data_c;
            data_d_stage1 <= data_d;
            select_stage1 <= select;
            write_en_stage1 <= write_en;
            valid_stage1 <= valid_in;
        end
    end
    
    // Stage 2: Memory write and read selection
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            buffers[0] <= 8'h0;
            buffers[1] <= 8'h0;
            buffers[2] <= 8'h0;
            buffers[3] <= 8'h0;
            data_selected_stage2 <= 8'h0;
            valid_stage2 <= 1'b0;
        end
        else begin
            // Pipeline valid signal
            valid_stage2 <= valid_stage1;
            
            // Memory write logic
            if (write_en_stage1 && valid_stage1) begin
                case (select_stage1)
                    2'b00: buffers[0] <= data_a_stage1;
                    2'b01: buffers[1] <= data_b_stage1;
                    2'b10: buffers[2] <= data_c_stage1;
                    2'b11: buffers[3] <= data_d_stage1;
                endcase
            end
            
            // Data selection for output
            data_selected_stage2 <= buffers[select_stage1];
        end
    end
    
    // Stage 3: Output registers
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= 8'h0;
            valid_out <= 1'b0;
        end
        else begin
            data_out <= data_selected_stage2;
            valid_out <= valid_stage2;
        end
    end
    
endmodule