module one_time_pad #(parameter WIDTH = 24) (
    input wire clk, reset_n,
    input wire activate, new_key,
    input wire [WIDTH-1:0] data_input, key_input,
    output reg [WIDTH-1:0] data_output,
    output reg ready
);
    reg [WIDTH-1:0] current_key;
    
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            current_key <= 0;
            data_output <= 0;
            ready <= 0;
        end else if (new_key) begin
            current_key <= key_input;
            ready <= 1;
        end else if (activate && ready) begin
            data_output <= data_input ^ current_key;
            ready <= 0;  // One-time use
        end
    end
endmodule
