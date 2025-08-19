//SystemVerilog
module simple_hamming32(
    input wire clk,
    input wire rst_n,
    input wire valid_in,
    output wire ready_out,
    input wire [31:0] data_in,
    output wire valid_out,
    input wire ready_in,
    output wire [38:0] data_out
);

    reg [38:0] data_out_reg;
    reg valid_out_reg;
    reg ready_out_reg;
    
    wire [5:0] parity;
    wire [15:0] xor_stage1 [5:0];
    wire [7:0] xor_stage2 [5:0];
    wire [3:0] xor_stage3 [5:0];
    wire [1:0] xor_stage4 [5:0];
    
    // ... existing parity calculation code ...
    
    // Assemble output
    assign data_out = data_out_reg;
    assign valid_out = valid_out_reg;
    assign ready_out = ready_out_reg;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out_reg <= 39'b0;
            valid_out_reg <= 1'b0;
            ready_out_reg <= 1'b1;
        end else begin
            if (valid_in && ready_out_reg) begin
                data_out_reg <= {data_in, parity, 1'b0};
                valid_out_reg <= 1'b1;
            end
            
            if (valid_out_reg && ready_in) begin
                valid_out_reg <= 1'b0;
            end
            
            ready_out_reg <= !valid_out_reg || ready_in;
        end
    end
endmodule