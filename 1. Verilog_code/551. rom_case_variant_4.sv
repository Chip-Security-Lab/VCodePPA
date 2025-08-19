//SystemVerilog
module rom_case #(parameter DW=8, AW=4)(
    input clk,
    input [AW-1:0] addr,
    output reg [DW-1:0] data_stage1,
    output reg [DW-1:0] data_stage2
);
    reg [AW-1:0] addr_stage1;
    reg [AW-1:0] addr_stage2;

    // Stage 1: Register the address
    always @(posedge clk) begin
        addr_stage1 <= addr;
    end

    // Stage 2: Decode the address
    always @(posedge clk) begin
        addr_stage2 <= addr_stage1;
    end

    // Stage 3: Produce output based on decoded address
    always @(addr_stage2) begin
        case(addr_stage2)
            4'h0: data_stage2 <= 8'h00;
            4'h1: data_stage2 <= 8'h11;
            4'h2: data_stage2 <= 8'h22;
            4'h3: data_stage2 <= 8'h33;
            4'h4: data_stage2 <= 8'h44;
            4'h5: data_stage2 <= 8'h55;
            4'h6: data_stage2 <= 8'h66;
            4'h7: data_stage2 <= 8'h77;
            4'h8: data_stage2 <= 8'h88;
            4'h9: data_stage2 <= 8'h99;
            4'hA: data_stage2 <= 8'hAA;
            4'hB: data_stage2 <= 8'hBB;
            4'hC: data_stage2 <= 8'hCC;
            4'hD: data_stage2 <= 8'hDD;
            4'hE: data_stage2 <= 8'hEE;
            4'hF: data_stage2 <= 8'hFF;
            default: data_stage2 <= 8'hFF; // 默认情况保留
        endcase
    end

    // Stage 4: Output the final data
    always @(posedge clk) begin
        data_stage1 <= data_stage2;
    end
endmodule