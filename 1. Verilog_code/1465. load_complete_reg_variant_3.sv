//SystemVerilog
module load_complete_reg(
    input clk, rst,
    input [15:0] data_in,
    input load,
    output [15:0] data_out,
    output load_done
);
    // Retimed registers for inputs
    reg load_r1, load_r2;
    reg [15:0] data_in_r;
    
    // Output registers
    reg [15:0] data_out_r;
    reg load_done_r;
    
    // First stage registers - capture inputs
    always @(posedge clk) begin
        if (rst) begin
            load_r1 <= 1'b0;
            data_in_r <= 16'h0;
        end else begin
            load_r1 <= load;
            data_in_r <= data_in;
        end
    end
    
    // Second stage - pull back register logic from output
    always @(posedge clk) begin
        if (rst) begin
            load_r2 <= 1'b0;
            data_out_r <= 16'h0;
        end else begin
            load_r2 <= load_r1;
            if (load_r1)
                data_out_r <= data_in_r;
        end
    end
    
    // Final stage - only registering the load_done signal
    always @(posedge clk) begin
        if (rst) begin
            load_done_r <= 1'b0;
        end else begin
            load_done_r <= load_r2;
        end
    end
    
    // Assign outputs
    assign data_out = data_out_r;
    assign load_done = load_done_r;
    
endmodule