//SystemVerilog
module cdc_detector #(
    parameter WIDTH = 8
)(
    input wire src_clk, dst_clk, rst,
    input wire [WIDTH-1:0] data_in,
    input wire src_valid,
    output reg [WIDTH-1:0] data_out,
    output reg dst_valid
);

    // State definitions
    localparam IDLE  = 2'b00;
    localparam SYNC1 = 2'b01;
    localparam SYNC2 = 2'b10;
    localparam VALID = 2'b11;

    // Internal signals
    reg [1:0] state, next;
    reg toggle_src;
    reg [1:0] toggle_dst_sync;
    reg [WIDTH-1:0] data_reg;

    // Source domain: Toggle and data capture
    always @(posedge src_clk or posedge rst) begin
        if (rst) begin
            toggle_src <= 1'b0;
            data_reg <= {WIDTH{1'b0}};
        end else if (src_valid) begin
            toggle_src <= ~toggle_src;
            data_reg <= data_in;
        end
    end

    // Destination domain: State machine
    always @(posedge dst_clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
        end else begin
            state <= next;
        end
    end

    // Destination domain: Toggle synchronization
    always @(posedge dst_clk or posedge rst) begin
        if (rst) begin
            toggle_dst_sync <= 2'b00;
        end else begin
            toggle_dst_sync <= {toggle_dst_sync[0], toggle_src};
        end
    end

    // Destination domain: Data output and valid generation
    always @(posedge dst_clk or posedge rst) begin
        if (rst) begin
            data_out <= {WIDTH{1'b0}};
            dst_valid <= 1'b0;
        end else begin
            if (state == VALID) begin
                data_out <= data_reg;
                dst_valid <= 1'b1;
            end else begin
                dst_valid <= 1'b0;
            end
        end
    end

    // Next state logic
    always @(*) begin
        case (state)
            IDLE:  next = (toggle_dst_sync[1] != toggle_dst_sync[0]) ? SYNC1 : IDLE;
            SYNC1: next = SYNC2;
            SYNC2: next = VALID;
            VALID: next = IDLE;
            default: next = IDLE;
        endcase
    end

endmodule