//SystemVerilog
// Top-level Parallel-to-Serial Mux Module with AXI4-Lite Interface
module Par2SerMux_AXI4Lite #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 4
)(
    input  wire                   clk,
    input  wire                   rst_n,

    // AXI4-Lite Write Address Channel
    input  wire [ADDR_WIDTH-1:0]  s_axi_awaddr,
    input  wire                   s_axi_awvalid,
    output reg                    s_axi_awready,

    // AXI4-Lite Write Data Channel
    input  wire [DATA_WIDTH-1:0]  s_axi_wdata,
    input  wire [(DATA_WIDTH/8)-1:0] s_axi_wstrb,
    input  wire                   s_axi_wvalid,
    output reg                    s_axi_wready,

    // AXI4-Lite Write Response Channel
    output reg  [1:0]             s_axi_bresp,
    output reg                    s_axi_bvalid,
    input  wire                   s_axi_bready,

    // AXI4-Lite Read Address Channel
    input  wire [ADDR_WIDTH-1:0]  s_axi_araddr,
    input  wire                   s_axi_arvalid,
    output reg                    s_axi_arready,

    // AXI4-Lite Read Data Channel
    output reg  [DATA_WIDTH-1:0]  s_axi_rdata,
    output reg  [1:0]             s_axi_rresp,
    output reg                    s_axi_rvalid,
    input  wire                   s_axi_rready,

    // Serial Output
    output wire                   ser_out
);

    // Internal Registers
    reg [DATA_WIDTH-1:0] parallel_data_reg;
    reg                  load_reg;

    // AXI4-Lite Internal Write FSM
    reg                  aw_en;
    reg [ADDR_WIDTH-1:0] awaddr_reg;
    reg [ADDR_WIDTH-1:0] araddr_reg;

    // Write Address Channel
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axi_awready <= 1'b0;
            aw_en         <= 1'b1;
            awaddr_reg    <= {ADDR_WIDTH{1'b0}};
        end else begin
            if (~s_axi_awready && s_axi_awvalid && aw_en) begin
                s_axi_awready <= 1'b1;
                awaddr_reg    <= s_axi_awaddr;
            end else if (s_axi_wvalid && s_axi_awready) begin
                s_axi_awready <= 1'b0;
                aw_en         <= 1'b0;
            end else if (s_axi_bready && s_axi_bvalid) begin
                aw_en         <= 1'b1;
            end else begin
                s_axi_awready <= 1'b0;
            end
        end
    end

    // Write Data Channel
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axi_wready <= 1'b0;
        end else begin
            if (~s_axi_wready && s_axi_wvalid && aw_en) begin
                s_axi_wready <= 1'b1;
            end else begin
                s_axi_wready <= 1'b0;
            end
        end
    end

    // Write Response Channel
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axi_bvalid <= 1'b0;
            s_axi_bresp  <= 2'b00;
        end else begin
            if (s_axi_awready && s_axi_awvalid && ~s_axi_bvalid && s_axi_wready && s_axi_wvalid) begin
                s_axi_bvalid <= 1'b1;
                s_axi_bresp  <= 2'b00; // OKAY response
            end else if (s_axi_bready && s_axi_bvalid) begin
                s_axi_bvalid <= 1'b0;
            end
        end
    end

    // Write Register Logic (Memory-mapped)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            parallel_data_reg <= {DATA_WIDTH{1'b0}};
            load_reg          <= 1'b0;
        end else begin
            load_reg <= 1'b0;
            if (s_axi_wready && s_axi_wvalid && s_axi_awready && s_axi_awvalid) begin
                case (awaddr_reg[ADDR_WIDTH-1:0])
                    4'h0: begin
                        // Write to parallel data register
                        if (s_axi_wstrb[0])
                            parallel_data_reg <= s_axi_wdata;
                    end
                    4'h4: begin
                        // Write to load register
                        if (s_axi_wstrb[0])
                            load_reg <= s_axi_wdata[0];
                    end
                    default: ;
                endcase
            end
        end
    end

    // Read Address Channel
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axi_arready <= 1'b0;
            araddr_reg    <= {ADDR_WIDTH{1'b0}};
        end else begin
            if (~s_axi_arready && s_axi_arvalid) begin
                s_axi_arready <= 1'b1;
                araddr_reg    <= s_axi_araddr;
            end else begin
                s_axi_arready <= 1'b0;
            end
        end
    end

    // Read Data Channel
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axi_rvalid <= 1'b0;
            s_axi_rdata  <= {DATA_WIDTH{1'b0}};
            s_axi_rresp  <= 2'b00;
        end else begin
            if (s_axi_arready && s_axi_arvalid && ~s_axi_rvalid) begin
                case (araddr_reg[ADDR_WIDTH-1:0])
                    4'h0: begin
                        s_axi_rdata <= parallel_data_reg;
                    end
                    4'h4: begin
                        s_axi_rdata <= {7'b0, load_reg};
                    end
                    4'h8: begin
                        s_axi_rdata <= {7'b0, ser_out};
                    end
                    default: begin
                        s_axi_rdata <= {DATA_WIDTH{1'b0}};
                    end
                endcase
                s_axi_rvalid <= 1'b1;
                s_axi_rresp  <= 2'b00; // OKAY response
            end else if (s_axi_rvalid && s_axi_rready) begin
                s_axi_rvalid <= 1'b0;
            end
        end
    end

    // Internal shift register output
    wire [DATA_WIDTH-1:0] shift_reg_out;

    // Shift Register Module Instance
    ShiftRegister #(.DW(DATA_WIDTH)) u_shift_register (
        .clk        (clk),
        .load       (load_reg),
        .data_in    (parallel_data_reg),
        .shift_out  (shift_reg_out)
    );

    // Serial Output Logic Instance
    SerialOutput u_serial_output (
        .shift_reg  (shift_reg_out),
        .ser_out    (ser_out)
    );

endmodule

// -----------------------------------------------------------------------------
// Shift Register Module
// Loads parallel data or shifts right on each clock
// -----------------------------------------------------------------------------
module ShiftRegister #(parameter DW=8) (
    input  wire             clk,
    input  wire             load,
    input  wire [DW-1:0]    data_in,
    output reg  [DW-1:0]    shift_out
);
    always @(posedge clk) begin
        if (load)
            shift_out <= data_in;
        else
            shift_out <= shift_out >> 1;
    end
endmodule

// -----------------------------------------------------------------------------
// Serial Output Module
// Outputs the least significant bit of the shift register
// -----------------------------------------------------------------------------
module SerialOutput (
    input  wire [7:0]   shift_reg, // Maximum width for parameterization
    output wire         ser_out
);
    assign ser_out = shift_reg[0];
endmodule