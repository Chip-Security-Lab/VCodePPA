//SystemVerilog
module cascaded_buffer (
    input wire clk,
    input wire [7:0] data_in,
    input wire valid_in,   // Replaces cascade_en (sender indicates data is valid)
    output wire ready_out, // New signal (receiver indicates ready to accept)
    output wire [7:0] data_out,
    output wire valid_out, // New signal (indicates output data is valid)
    input wire ready_in    // New signal (next stage indicates ready to accept)
);
    reg [7:0] buffer1, buffer2, buffer3;
    reg valid1, valid2, valid3;
    
    // Ready signal generation - propagates backward through the pipeline
    wire ready3 = ready_in;
    wire ready2 = ready3 || !valid3;
    wire ready1 = ready2 || !valid2;
    assign ready_out = ready1 || !valid1;
    
    // First buffer stage
    always @(posedge clk) begin
        if (valid_in && ready_out) begin
            buffer1 <= data_in;
            valid1 <= 1'b1;
        end else if (ready1) begin
            valid1 <= 1'b0;
        end
    end
    
    // Second buffer stage
    always @(posedge clk) begin
        if (valid1 && ready1) begin
            buffer2 <= buffer1;
            valid2 <= 1'b1;
        end else if (ready2) begin
            valid2 <= 1'b0;
        end
    end
    
    // Third buffer stage
    always @(posedge clk) begin
        if (valid2 && ready2) begin
            buffer3 <= buffer2;
            valid3 <= 1'b1;
        end else if (ready3) begin
            valid3 <= 1'b0;
        end
    end
    
    // Output assignments
    assign data_out = buffer3;
    assign valid_out = valid3;
endmodule