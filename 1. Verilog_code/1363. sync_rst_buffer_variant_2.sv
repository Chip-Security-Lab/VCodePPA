//SystemVerilog
module sync_rst_buffer (
    input wire clk,
    input wire rst,
    input wire [31:0] data_in,
    input wire load,
    output reg [31:0] data_out,
    input wire ready_in,
    output wire ready_out,
    output reg valid_out
);
    // Pipeline stage 1 registers
    reg [31:0] data_stage1;
    reg valid_stage1;
    
    // Pipeline stage 2 registers
    reg [31:0] data_stage2;
    reg valid_stage2;
    
    // Pre-compute ready signals to reduce critical path
    wire stage1_ready;
    wire stage2_ready;
    wire output_ready;
    
    // Balanced ready signal propagation
    assign output_ready = ready_in || !valid_out;
    assign stage2_ready = ready_in || !valid_stage2;
    assign stage1_ready = output_ready;
    
    // Expose the ready_out signal
    assign ready_out = output_ready;
    
    // Pipeline stage 1 - Input capture with simplified conditions
    always @(posedge clk) begin
        if (rst) begin
            data_stage1 <= 32'b0;
            valid_stage1 <= 1'b0;
        end else begin
            if (stage1_ready && load) begin
                data_stage1 <= data_in;
                valid_stage1 <= 1'b1;
            end else if (stage1_ready) begin
                valid_stage1 <= 1'b0;
            end
        end
    end
    
    // Pipeline stage 2 - Processing with balanced logic
    always @(posedge clk) begin
        if (rst) begin
            data_stage2 <= 32'b0;
            valid_stage2 <= 1'b0;
        end else if (stage2_ready) begin
            data_stage2 <= data_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Output stage with optimized logic
    always @(posedge clk) begin
        if (rst) begin
            data_out <= 32'b0;
            valid_out <= 1'b0;
        end else if (output_ready) begin
            data_out <= data_stage2;
            valid_out <= valid_stage2;
        end
    end
endmodule