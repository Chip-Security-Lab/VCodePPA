//SystemVerilog
module circ_right_shift #(parameter BITS = 4) (
    input wire clk,
    input wire rst_n,
    input wire en,
    output wire [BITS-1:0] q
);
    reg [BITS-1:0] shifter;
    reg [BITS-1:0] shifter_buf1;
    reg [BITS-1:0] shifter_buf2;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            shifter <= {{BITS-1{1'b0}}, 1'b1};  // Initialize with one hot
        else if (en)
            shifter <= {shifter[0], shifter[BITS-1:1]};
    end
    
    // Add buffer registers to reduce fan-out load
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shifter_buf1 <= {{BITS-1{1'b0}}, 1'b1};
            shifter_buf2 <= {{BITS-1{1'b0}}, 1'b1};
        end
        else begin
            shifter_buf1 <= shifter;
            shifter_buf2 <= shifter;
        end
    end
    
    // Using buffer registers for output to balance load
    assign q = shifter_buf1;
endmodule