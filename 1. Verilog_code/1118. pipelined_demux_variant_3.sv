//SystemVerilog
module pipelined_demux_valid_ready (
    input  wire        clk,            // System clock
    input  wire        rst_n,          // Asynchronous active-low reset
    input  wire        data_valid,     // Input data valid
    input  wire        data_in,        // Input data
    input  wire [1:0]  addr_in,        // Address selection
    output reg         data_ready,     // Input data ready
    output reg  [3:0]  demux_out,      // Output channels
    output reg         demux_valid,    // Output data valid
    input  wire        demux_ready     // Output data ready
);

    reg        data_reg;
    reg [1:0]  addr_reg;
    reg        valid_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_reg     <= 1'b0;
            addr_reg     <= 2'b00;
            valid_reg    <= 1'b0;
            demux_out    <= 4'b0;
            demux_valid  <= 1'b0;
            data_ready   <= 1'b1;
        end else begin
            // Input ready: only accept data if pipeline is ready to move forward
            data_ready <= !valid_reg || (demux_valid && demux_ready);

            // Pipeline stage 1: capture input data/addr and valid, only if input handshake occurs
            case ({data_valid && data_ready, demux_valid && demux_ready})
                2'b10: begin
                    data_reg  <= data_in;
                    addr_reg  <= addr_in;
                    valid_reg <= 1'b1;
                end
                2'b01: begin
                    valid_reg <= 1'b0;
                end
                default: begin
                    // Hold previous values
                end
            endcase

            // Pipeline stage 2: output data if valid and output is ready
            case ({valid_reg, demux_valid && demux_ready, demux_ready || !demux_valid})
                3'b100: begin // valid_reg=1, demux_valid && demux_ready=0, demux_ready||!demux_valid=0
                    // Hold previous values
                end
                3'b101, 3'b111: begin // valid_reg=1, demux_ready||!demux_valid=1
                    demux_out            <= 4'b0;
                    case (addr_reg)
                        2'b00: demux_out[0] <= data_reg;
                        2'b01: demux_out[1] <= data_reg;
                        2'b10: demux_out[2] <= data_reg;
                        2'b11: demux_out[3] <= data_reg;
                        default: demux_out  <= 4'b0;
                    endcase
                    demux_valid          <= 1'b1;
                end
                3'b010, 3'b011: begin // valid_reg=0, demux_valid && demux_ready=1
                    demux_out   <= 4'b0;
                    demux_valid <= 1'b0;
                end
                3'b000: begin // valid_reg=0, demux_valid && demux_ready=0, demux_ready||!demux_valid=0
                    demux_out   <= 4'b0;
                    demux_valid <= 1'b0;
                end
                default: begin
                    // Hold previous values
                end
            endcase
        end
    end

endmodule