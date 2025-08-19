module differential_encoder (
    input  wire       clock,
    input  wire       reset,
    input  wire       enable,
    input  wire       data_input,
    output reg        diff_encoded
);
    reg prev_encoded;
    
    always @(posedge clock) begin
        if (reset) begin
            diff_encoded <= 1'b0;
            prev_encoded <= 1'b0;
        end else if (enable) begin
            diff_encoded <= data_input ^ prev_encoded;
            prev_encoded <= diff_encoded;
        end
    end
endmodule