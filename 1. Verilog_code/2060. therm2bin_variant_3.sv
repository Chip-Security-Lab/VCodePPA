//SystemVerilog
module therm2bin #(
    parameter THERM_WIDTH = 7,
    parameter BIN_WIDTH = 3 // $clog2(THERM_WIDTH+1) is not synthesizable, so use fixed value
) (
    input wire clk,
    input wire rst_n,
    input wire start,
    input wire [THERM_WIDTH-1:0] therm_in,
    output reg [BIN_WIDTH-1:0] bin_out,
    output reg done
);

    // State encoding
    localparam IDLE      = 2'd0;
    localparam COUNT     = 2'd1;
    localparam FINISHED  = 2'd2;

    reg [1:0] state, next_state;
    reg [BIN_WIDTH-1:0] bin_out_next;
    reg [$clog2(THERM_WIDTH):0] idx, idx_next;
    reg done_next;

    // State register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state   <= IDLE;
            bin_out <= {BIN_WIDTH{1'b0}};
            idx     <= {($clog2(THERM_WIDTH)+1){1'b0}};
            done    <= 1'b0;
        end else begin
            state   <= next_state;
            bin_out <= bin_out_next;
            idx     <= idx_next;
            done    <= done_next;
        end
    end

    // Next-state logic
    always @(*) begin
        next_state   = state;
        bin_out_next = bin_out;
        idx_next     = idx;
        done_next    = done;
        case (state)
            IDLE: begin
                done_next    = 1'b0;
                bin_out_next = {BIN_WIDTH{1'b0}};
                idx_next     = {($clog2(THERM_WIDTH)+1){1'b0}};
                if (start) begin
                    next_state = COUNT;
                end
            end
            COUNT: begin
                bin_out_next = bin_out + therm_in[idx];
                idx_next     = idx + 1'b1;
                if (idx == (THERM_WIDTH-1)) begin
                    next_state = FINISHED;
                end
            end
            FINISHED: begin
                done_next    = 1'b1;
                next_state   = IDLE;
            end
            default: begin
                next_state   = IDLE;
                bin_out_next = {BIN_WIDTH{1'b0}};
                idx_next     = {($clog2(THERM_WIDTH)+1){1'b0}};
                done_next    = 1'b0;
            end
        endcase
    end

endmodule