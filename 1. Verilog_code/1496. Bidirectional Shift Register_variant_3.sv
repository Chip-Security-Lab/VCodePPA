//SystemVerilog
module bidir_shift_reg #(parameter WIDTH = 8) (
    input wire clk, rst, en, dir, data_in,
    output wire [WIDTH-1:0] q_out
);
    reg [WIDTH-1:0] shiftreg;
    reg [WIDTH-1:0] shiftreg_buf1;
    reg [WIDTH-1:0] shiftreg_buf2;
    
    // Left shift logic
    always @(posedge clk) begin
        if (rst)
            shiftreg[WIDTH-2:0] <= 0;
        else if (en && dir)
            shiftreg[WIDTH-2:0] <= shiftreg[WIDTH-3:0];
    end
    
    // Right shift logic
    always @(posedge clk) begin
        if (rst)
            shiftreg[WIDTH-1:1] <= 0;
        else if (en && !dir)
            shiftreg[WIDTH-1:1] <= shiftreg[WIDTH-2:0];
    end
    
    // LSB logic (for left shift)
    always @(posedge clk) begin
        if (rst)
            shiftreg[0] <= 1'b0;
        else if (en && dir)
            shiftreg[0] <= data_in;
    end
    
    // MSB logic (for right shift)
    always @(posedge clk) begin
        if (rst)
            shiftreg[WIDTH-1] <= 1'b0;
        else if (en && !dir)
            shiftreg[WIDTH-1] <= data_in;
    end
    
    // Buffer stage 1 - first half
    always @(posedge clk) begin
        if (rst)
            shiftreg_buf1[WIDTH/2-1:0] <= 0;
        else
            shiftreg_buf1[WIDTH/2-1:0] <= shiftreg[WIDTH/2-1:0];
    end
    
    // Buffer stage 1 - second half
    always @(posedge clk) begin
        if (rst)
            shiftreg_buf1[WIDTH-1:WIDTH/2] <= 0;
        else
            shiftreg_buf1[WIDTH-1:WIDTH/2] <= shiftreg[WIDTH-1:WIDTH/2];
    end
    
    // Buffer stage 2 - first half
    always @(posedge clk) begin
        if (rst)
            shiftreg_buf2[WIDTH/2-1:0] <= 0;
        else
            shiftreg_buf2[WIDTH/2-1:0] <= shiftreg_buf1[WIDTH/2-1:0];
    end
    
    // Buffer stage 2 - second half
    always @(posedge clk) begin
        if (rst)
            shiftreg_buf2[WIDTH-1:WIDTH/2] <= 0;
        else
            shiftreg_buf2[WIDTH-1:WIDTH/2] <= shiftreg_buf1[WIDTH-1:WIDTH/2];
    end
    
    // Output assignment
    assign q_out = shiftreg_buf2;
endmodule