module BasicIVMU (
    input wire clk, rst_n,
    input wire [7:0] int_req,
    output reg [31:0] vector_addr,
    output reg int_valid
);
    reg [31:0] vec_table [0:7];
    integer i;
    
    initial begin
        for (i = 0; i < 8; i = i + 1)
            vec_table[i] = 32'h1000_0000 + (i << 2);
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            vector_addr <= 32'h0; int_valid <= 1'b0;
        end else begin
            int_valid <= 1'b0;
            for (i = 0; i < 8; i = i + 1) begin
                if (int_req[i]) begin
                    vector_addr <= vec_table[i];
                    int_valid <= 1'b1;
                end
            end
        end
    end
endmodule