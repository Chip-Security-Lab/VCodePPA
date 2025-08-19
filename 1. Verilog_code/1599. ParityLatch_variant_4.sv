//SystemVerilog
module ParityLatch #(parameter DW=7) (
    input clk, rst_n, en,
    input [DW-1:0] data,
    output reg [DW:0] q
);

// Stage 1: Carry Chain Generation
reg [DW-1:0] carry_chain_stage1;
reg [DW-1:0] borrow_stage1;
reg [DW-1:0] data_stage1;
reg en_stage1;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        carry_chain_stage1 <= {DW{1'b0}};
        borrow_stage1 <= {DW{1'b0}};
        data_stage1 <= {DW{1'b0}};
        en_stage1 <= 1'b0;
    end else begin
        carry_chain_stage1[0] <= 1'b0;
        borrow_stage1[0] <= ~data[0];
        data_stage1 <= data;
        en_stage1 <= en;
    end
end

// Stage 2: Carry Chain Propagation
reg [DW-1:0] carry_chain_stage2;
reg [DW-1:0] borrow_stage2;
reg [DW-1:0] data_stage2;
reg en_stage2;

genvar i;
generate
    for (i = 1; i < DW; i = i + 1) begin : carry_chain_gen
        always @(posedge clk or negedge rst_n) begin
            if (!rst_n) begin
                carry_chain_stage2[i] <= 1'b0;
                borrow_stage2[i] <= 1'b0;
            end else begin
                carry_chain_stage2[i] <= carry_chain_stage1[i-1] & ~data_stage1[i-1];
                borrow_stage2[i] <= ~data_stage1[i] ^ carry_chain_stage2[i];
            end
        end
    end
endgenerate

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        data_stage2 <= {DW{1'b0}};
        en_stage2 <= 1'b0;
    end else begin
        data_stage2 <= data_stage1;
        en_stage2 <= en_stage1;
    end
end

// Stage 3: Parity Calculation and Output
reg parity_bit_stage3;
reg [DW-1:0] data_stage3;
reg en_stage3;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        parity_bit_stage3 <= 1'b0;
        data_stage3 <= {DW{1'b0}};
        en_stage3 <= 1'b0;
    end else begin
        parity_bit_stage3 <= ^borrow_stage2;
        data_stage3 <= data_stage2;
        en_stage3 <= en_stage2;
    end
end

// Output Stage
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        q <= {(DW+1){1'b0}};
    end else if (en_stage3) begin
        q <= {parity_bit_stage3, data_stage3};
    end
end

endmodule