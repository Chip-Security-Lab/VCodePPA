//SystemVerilog
module dram_mode_register #(
    parameter MR_ADDR_WIDTH = 4
)(
    input clk,
    input load_mr,
    input [MR_ADDR_WIDTH-1:0] mr_addr,
    input [15:0] mr_data,
    output reg [15:0] current_mode
);

    // Mode register array
    reg [15:0] mode_regs [0:(1<<MR_ADDR_WIDTH)-1];
    
    // Parallel prefix subtractor signals
    wire [15:0] sub_result;
    wire [15:0] carry_propagate;
    wire [15:0] carry_generate;
    
    // Parallel prefix subtractor implementation
    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : sub_pp
            // Generate and propagate signals
            assign carry_generate[i] = ~mr_data[i] & mode_regs[mr_addr][i];
            assign carry_propagate[i] = mr_data[i] ^ mode_regs[mr_addr][i];
            
            // First level of prefix computation
            if (i == 0) begin
                assign sub_result[i] = carry_propagate[i];
            end else begin
                assign sub_result[i] = carry_propagate[i] ^ carry_generate[i-1];
            end
        end
    endgenerate

    // Mode register write logic
    always @(posedge clk) begin
        if (load_mr) begin
            mode_regs[mr_addr] <= mr_data;
        end
    end

    // Mode register read logic with parallel prefix subtraction
    always @(posedge clk) begin
        current_mode <= sub_result;
    end

endmodule