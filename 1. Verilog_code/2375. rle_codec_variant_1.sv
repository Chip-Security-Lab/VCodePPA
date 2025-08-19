//SystemVerilog
module rle_codec (
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_in,
    output reg [7:0] data_out
);

    // Pipeline stage registers 
    reg [7:0] data_in_r1;
    reg [7:0] count_r;
    reg is_control_r;
    
    // Pipeline stage 1: Input capture and analysis - 扁平化结构
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_in_r1 <= 8'h00;
            is_control_r <= 1'b0;
        end else begin
            data_in_r1 <= data_in;
            is_control_r <= data_in[7];
        end
    end
    
    // Pipeline stage 2: Counter management with flattened logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count_r <= 8'h00;
        end else if (is_control_r) begin
            count_r <= {1'b0, data_in_r1[6:0]};
        end else if (|count_r) begin
            count_r <= count_r - 8'h01;
        end else begin
            count_r <= count_r;
        end
    end
    
    // Pipeline stage 3: Output generation with simplified control
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= 8'h00;
        end else if (is_control_r) begin
            data_out <= 8'h00;
        end else begin
            data_out <= data_in_r1;
        end
    end

endmodule