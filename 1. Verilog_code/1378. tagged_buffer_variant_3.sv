//SystemVerilog
module tagged_buffer (
    input wire clk,
    input wire rst_n,
    input wire [15:0] data_in,
    input wire [3:0] tag_in,
    input wire write_en,
    input wire ready_out,
    output reg valid_out,
    output reg [15:0] data_out,
    output reg [3:0] tag_out,
    output wire ready_in
);
    // Pre-computation registers for data path (moved backward from output)
    reg [15:0] data_pre_out;
    reg [3:0] tag_pre_out;
    
    // Pipeline control signals
    reg valid_stage1;
    reg valid_pre_out;
    
    // Handshaking and flow control - optimized for better backpressure handling
    assign ready_in = !valid_pre_out || ready_out;
    
    // First pipeline stage - data capture
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_pre_out <= 16'b0;
            tag_pre_out <= 4'b0;
            valid_stage1 <= 1'b0;
        end else if (write_en && ready_in) begin
            data_pre_out <= data_in;
            tag_pre_out <= tag_in;
            valid_stage1 <= 1'b1;
        end else if (ready_out) begin
            valid_stage1 <= 1'b0;
        end
    end
    
    // Pre-output register stage (retimed from output)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_pre_out <= 1'b0;
        end else if (valid_stage1 && ready_out) begin
            valid_pre_out <= valid_stage1;
        end else if (ready_out) begin
            valid_pre_out <= 1'b0;
        end
    end
    
    // Output stage - moved backward
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= 16'b0;
            tag_out <= 4'b0;
            valid_out <= 1'b0;
        end else if (valid_pre_out && ready_out) begin
            data_out <= data_pre_out; // Direct connection from pre-output registers
            tag_out <= tag_pre_out;   // Direct connection from pre-output registers
            valid_out <= valid_pre_out;
        end else if (ready_out) begin
            valid_out <= 1'b0;
        end
    end
    
endmodule