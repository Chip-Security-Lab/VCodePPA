//SystemVerilog
module decoder_arbiter #(
    parameter NUM_MASTERS = 2
) (
    input  logic clk,
    input  logic rst_n,
    input  logic [NUM_MASTERS-1:0] req,
    output logic [NUM_MASTERS-1:0] grant
);

// Pipeline registers
logic [NUM_MASTERS-1:0] req_reg;
logic [NUM_MASTERS-1:0] req_inv_reg;
logic [NUM_MASTERS-1:0] borrow_reg;
logic [NUM_MASTERS-1:0] diff_reg;
logic [NUM_MASTERS-1:0] grant_reg;

// Stage 1: Request processing
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        req_reg <= '0;
    end else begin
        req_reg <= req;
    end
end

// Stage 2: Inverted request generation
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        req_inv_reg <= '0;
    end else begin
        req_inv_reg <= ~req_reg;
    end
end

// Stage 3: Borrow signal generation
logic [NUM_MASTERS-1:0] borrow;
assign borrow[0] = 1'b1;

genvar i;
generate
    for (i = 1; i < NUM_MASTERS; i = i + 1) begin : borrow_gen
        assign borrow[i] = ~req_inv_reg[i-1] & borrow[i-1];
    end
endgenerate

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        borrow_reg <= '0;
    end else begin
        borrow_reg <= borrow;
    end
end

// Stage 4: Difference calculation
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        diff_reg <= '0;
    end else begin
        diff_reg <= req_inv_reg + borrow_reg;
    end
end

// Stage 5: Grant generation
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        grant_reg <= '0;
    end else begin
        grant_reg <= req_reg & diff_reg;
    end
end

// Output assignment
assign grant = grant_reg;

endmodule