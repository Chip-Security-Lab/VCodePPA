//SystemVerilog
module enabled_ring_counter(
    input wire clock,
    input wire reset,
    input wire enable,
    output reg [3:0] count
);
    reg enable_reg;
    reg [3:0] count_next;
    
    always @(posedge clock) begin
        if (reset) begin
            enable_reg <= 1'b0;
            count <= 4'b0001;
        end else if (!reset && enable_reg) begin
            count <= count_next;
            enable_reg <= enable;
        end else begin
            enable_reg <= enable;
        end
    end
    
    always @(*) begin
        count_next = {count[2:0], count[3]};
    end
endmodule