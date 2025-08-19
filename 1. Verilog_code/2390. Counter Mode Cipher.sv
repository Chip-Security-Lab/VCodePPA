module counter_mode_cipher #(parameter CTR_WIDTH = 16, DATA_WIDTH = 32) (
    input wire clk, reset,
    input wire enable, encrypt,
    input wire [CTR_WIDTH-1:0] init_ctr,
    input wire [DATA_WIDTH-1:0] data_in, key,
    output reg [DATA_WIDTH-1:0] data_out,
    output reg data_valid
);
    reg [CTR_WIDTH-1:0] counter;
    wire [DATA_WIDTH-1:0] encrypted_ctr;
    
    // Simple encryption function (would be more complex in practice)
    assign encrypted_ctr = {counter, counter} ^ key;
    
    always @(posedge clk) begin
        if (reset) begin
            counter <= init_ctr;
            data_valid <= 0;
        end else if (enable) begin
            data_out <= data_in ^ encrypted_ctr;
            counter <= counter + 1;
            data_valid <= 1;
        end else begin
            data_valid <= 0;
        end
    end
endmodule