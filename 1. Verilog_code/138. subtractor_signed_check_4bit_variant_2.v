module subtractor_signed_check_4bit (
    input  wire        clk,
    input  wire        rst_n,
    input  wire signed [3:0] a, 
    input  wire signed [3:0] b, 
    output reg  signed [3:0] diff, 
    output reg         negative
);

    // Internal signals
    wire signed [3:0] diff_next;
    wire negative_next;
    
    // Combinational logic for subtraction
    assign diff_next = a - b;
    assign negative_next = diff_next[3];
    
    // Sequential logic with pipeline register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            diff <= 4'b0;
            negative <= 1'b0;
        end else begin
            diff <= diff_next;
            negative <= negative_next;
        end
    end

endmodule