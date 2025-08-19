//SystemVerilog
module cascade_parity (
    input clk,
    input rst_n,
    input [7:0] data,
    input valid,
    output ready,
    output reg parity,
    output reg parity_valid
);

reg data_received;
wire [3:0] nib_par;
wire computed_parity;
reg [1:0] state;
reg [3:0] nib_par_reg;
reg computed_parity_reg;

localparam IDLE = 2'b00;
localparam PROCESS = 2'b01;
localparam DONE = 2'b10;

// First stage: Calculate nibble parity
assign nib_par[0] = ^data[3:0];
assign nib_par[1] = ^data[7:4];

// Register the nibble parity results
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        nib_par_reg <= 4'b0;
    end else if (valid && ready) begin
        nib_par_reg <= nib_par;
    end
end

// Second stage: Calculate final parity
assign computed_parity = ^nib_par_reg;

// Register the final parity result
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        computed_parity_reg <= 1'b0;
    end else if (state == PROCESS) begin
        computed_parity_reg <= computed_parity;
    end
end

assign ready = !data_received || !parity_valid;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state <= IDLE;
        data_received <= 1'b0;
        parity <= 1'b0;
        parity_valid <= 1'b0;
    end else begin
        case (state)
            IDLE: begin
                if (valid && ready) begin
                    state <= PROCESS;
                    data_received <= 1'b1;
                end
            end
            PROCESS: begin
                state <= DONE;
                parity <= computed_parity_reg;
                parity_valid <= 1'b1;
            end
            DONE: begin
                state <= IDLE;
                parity_valid <= 1'b0;
                data_received <= 1'b0;
            end
            default: state <= IDLE;
        endcase
    end
end

endmodule