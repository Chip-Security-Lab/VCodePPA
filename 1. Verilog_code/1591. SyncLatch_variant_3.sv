//SystemVerilog
module SyncLatch #(parameter WIDTH=8) (
    input clk, rst_n, en,
    input [WIDTH-1:0] d,
    output reg [WIDTH-1:0] q
);

    // Generate and propagate signals for carry lookahead
    wire [WIDTH-1:0] g, p;
    reg [WIDTH-1:0] p_buf;
    wire [WIDTH:0] carry;
    reg [WIDTH:0] carry_buf;
    reg [WIDTH:0] carry_buf_stage1;
    reg [WIDTH:0] carry_buf_stage2;
    
    // Generate and propagate logic
    genvar i;
    generate
        for(i=0; i<WIDTH; i=i+1) begin: gen_prop
            assign g[i] = d[i] & en;
            assign p[i] = d[i] ^ en;
        end
    endgenerate
    
    // Buffer high fanout signals with two-stage pipeline
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            p_buf <= 0;
            carry_buf <= 0;
            carry_buf_stage1 <= 0;
            carry_buf_stage2 <= 0;
        end else begin
            p_buf <= p;
            carry_buf_stage1 <= carry;
            carry_buf_stage2 <= carry_buf_stage1;
            carry_buf <= carry_buf_stage2;
        end
    end
    
    // Carry lookahead logic with buffered signals
    assign carry[0] = 0;
    genvar j;
    generate
        for(j=0; j<WIDTH; j=j+1) begin: carry_gen
            assign carry[j+1] = g[j] | (p_buf[j] & carry_buf[j]);
        end
    endgenerate
    
    // Output logic with buffered carry lookahead
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) 
            q <= 0;
        else if(en)
            q <= p_buf ^ carry_buf[WIDTH-1:0];
    end

endmodule