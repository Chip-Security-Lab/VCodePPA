//SystemVerilog
module decoder_err_detect #(MAX_ADDR=16'hFFFF) (
    input clk,
    input rst_n,
    input [15:0] addr,
    output reg select,
    output reg err
);

// Pipeline stage registers
reg [15:0] addr_reg;
reg [15:0] shift_reg;
reg [15:0] acc_reg;
reg [4:0] count;
reg mult_done;
reg [15:0] result_reg;

// Merged pipeline stages with same clock and reset
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        // Reset all registers
        addr_reg <= 16'h0000;
        shift_reg <= 16'h0000;
        acc_reg <= 16'h0000;
        count <= 5'd0;
        mult_done <= 1'b0;
        result_reg <= 16'h0000;
        select <= 1'b0;
        err <= 1'b0;
    end else begin
        // Stage 1: Input registration
        addr_reg <= addr;
        
        // Stage 2: Multiplication pipeline
        if (!mult_done) begin
            if (count == 5'd16) begin
                mult_done <= 1'b1;
            end else begin
                if (shift_reg[0]) begin
                    acc_reg <= acc_reg + (MAX_ADDR << count);
                end
                shift_reg <= shift_reg >> 1;
                count <= count + 1'b1;
            end
        end
        
        // Stage 3: Result registration
        if (mult_done) begin
            result_reg <= acc_reg;
        end
        
        // Stage 4: Output generation
        select <= (result_reg < MAX_ADDR);
        err <= (result_reg >= MAX_ADDR);
    end
end

endmodule