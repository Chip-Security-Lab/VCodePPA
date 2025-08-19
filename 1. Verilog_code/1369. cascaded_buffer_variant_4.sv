//SystemVerilog
module cascaded_buffer (
    input  wire       clk,
    input  wire [7:0] data_in,
    input  wire       valid_in,
    output wire       ready_out,
    output wire [7:0] data_out,
    output wire       valid_out,
    input  wire       ready_in
);
    reg [7:0] buffer1, buffer2, buffer3;
    reg       valid1, valid2, valid3;
    
    // Ready signal generation - ready when next stage is ready or not valid
    wire ready2 = ready_in || !valid3;
    wire ready1 = ready2 || !valid2;
    assign ready_out = ready1 || !valid1;
    
    // First stage buffer management
    always @(posedge clk) begin
        if (ready_out && valid_in) begin
            buffer1 <= data_in;
            valid1 <= 1'b1;
        end else if (ready1) begin
            valid1 <= 1'b0;
        end
    end
    
    // Second stage buffer management
    always @(posedge clk) begin
        if (ready1 && valid1) begin
            buffer2 <= buffer1;
            valid2 <= 1'b1;
        end else if (ready2) begin
            valid2 <= 1'b0;
        end
    end
    
    // Third stage buffer management
    always @(posedge clk) begin
        if (ready2 && valid2) begin
            buffer3 <= buffer2;
            valid3 <= 1'b1;
        end else if (ready_in) begin
            valid3 <= 1'b0;
        end
    end
    
    // Output assignments
    assign data_out = buffer3;
    assign valid_out = valid3;
    
endmodule