//SystemVerilog
module axi4lite_mux #(
    parameter ADDR_WIDTH = 4,    // Enough for 5 channels + control
    parameter DATA_WIDTH = 16
)(
    input  wire                   axi_aclk,
    input  wire                   axi_aresetn,

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
    output reg [1:0]              s_axi_bresp,
    output reg                    s_axi_bvalid,
    input  wire                   s_axi_bready,

    // AXI4-Lite Read Address Channel
    input  wire [ADDR_WIDTH-1:0]  s_axi_araddr,
    input  wire                   s_axi_arvalid,
    output reg                    s_axi_arready,

    // AXI4-Lite Read Data Channel
    output reg [DATA_WIDTH-1:0]   s_axi_rdata,
    output reg [1:0]              s_axi_rresp,
    output reg                    s_axi_rvalid,
    input  wire                   s_axi_rready
);

    // Internal registers
    reg [2:0]                     channel_selector;
    reg [DATA_WIDTH-1:0]          channel_data [0:4];
    reg [DATA_WIDTH-1:0]          selected_data;

    // Hybrid-encoded Write FSM states
    // Frequent states (WR_IDLE, WR_RESP) use one-hot encoding
    // Less frequent state (WR_DATA, reserved) use binary encoding
    localparam WR_IDLE   = 4'b0001; // one-hot
    localparam WR_RESP   = 4'b0010; // one-hot
    localparam WR_DATA   = 4'b0100; // binary encoding for less frequent
    localparam WR_RSVD   = 4'b1000; // binary encoding for reserved/unused

    reg [3:0] wr_state, wr_state_next;

    // Hybrid-encoded Read FSM states
    // Frequent states (RD_IDLE, RD_DATA) use one-hot encoding
    localparam RD_IDLE   = 2'b01; // one-hot
    localparam RD_DATA   = 2'b10; // one-hot

    reg [1:0] rd_state, rd_state_next;

    integer i;

    // Write FSM sequential logic
    always @(posedge axi_aclk) begin
        if (!axi_aresetn) begin
            wr_state         <= WR_IDLE;
            s_axi_awready    <= 1'b0;
            s_axi_wready     <= 1'b0;
            s_axi_bvalid     <= 1'b0;
            s_axi_bresp      <= 2'b00;
        end else begin
            wr_state <= wr_state_next;
        end
    end

    // Write FSM next-state and output logic (combinational)
    always @(*) begin
        // Default assignments
        wr_state_next    = wr_state;
        s_axi_awready    = 1'b0;
        s_axi_wready     = 1'b0;
        s_axi_bvalid     = 1'b0;
        s_axi_bresp      = s_axi_bresp;

        case (wr_state)
            WR_IDLE: begin
                s_axi_awready = 1'b1;
                s_axi_wready  = 1'b1;
                if (s_axi_awvalid && s_axi_wvalid) begin
                    wr_state_next   = WR_RESP;
                    s_axi_awready   = 1'b0;
                    s_axi_wready    = 1'b0;
                    s_axi_bvalid    = 1'b1;
                    s_axi_bresp     = 2'b00; // OKAY

                    // Address decoding for write
                    case (s_axi_awaddr[ADDR_WIDTH-1:0])
                        4'h0: channel_data[0] = s_axi_wdata;
                        4'h2: channel_data[1] = s_axi_wdata;
                        4'h4: channel_data[2] = s_axi_wdata;
                        4'h6: channel_data[3] = s_axi_wdata;
                        4'h8: channel_data[4] = s_axi_wdata;
                        4'hC: channel_selector = s_axi_wdata[2:0];
                        default: ; // Do nothing for invalid addresses
                    endcase
                end
            end
            WR_RESP: begin
                s_axi_bvalid = 1'b1;
                s_axi_bresp  = 2'b00; // OKAY
                if (s_axi_bready) begin
                    wr_state_next = WR_IDLE;
                    s_axi_bvalid  = 1'b0;
                end
            end
            WR_DATA: begin
                // Reserved for future use or complex FSM expansion
                wr_state_next = WR_IDLE;
            end
            default: wr_state_next = WR_IDLE;
        endcase
    end

    // Read FSM sequential logic
    always @(posedge axi_aclk) begin
        if (!axi_aresetn) begin
            rd_state      <= RD_IDLE;
            s_axi_arready <= 1'b0;
            s_axi_rvalid  <= 1'b0;
            s_axi_rresp   <= 2'b00;
            s_axi_rdata   <= {DATA_WIDTH{1'b0}};
        end else begin
            rd_state <= rd_state_next;
        end
    end

    // Read FSM next-state and output logic (combinational)
    always @(*) begin
        // Default assignments
        rd_state_next   = rd_state;
        s_axi_arready   = 1'b0;
        s_axi_rvalid    = 1'b0;
        s_axi_rresp     = s_axi_rresp;
        s_axi_rdata     = s_axi_rdata;

        case (rd_state)
            RD_IDLE: begin
                s_axi_arready = 1'b1;
                if (s_axi_arvalid) begin
                    s_axi_arready = 1'b0;
                    s_axi_rvalid  = 1'b1;
                    s_axi_rresp   = 2'b00; // OKAY
                    case (s_axi_araddr[ADDR_WIDTH-1:0])
                        4'h0: s_axi_rdata = channel_data[0];
                        4'h2: s_axi_rdata = channel_data[1];
                        4'h4: s_axi_rdata = channel_data[2];
                        4'h6: s_axi_rdata = channel_data[3];
                        4'h8: s_axi_rdata = channel_data[4];
                        4'hA: s_axi_rdata = selected_data;
                        4'hC: s_axi_rdata = {13'b0, channel_selector};
                        default: s_axi_rdata = {DATA_WIDTH{1'b0}};
                    endcase
                    rd_state_next = RD_DATA;
                end
            end
            RD_DATA: begin
                s_axi_rvalid = 1'b1;
                if (s_axi_rready) begin
                    s_axi_rvalid  = 1'b0;
                    rd_state_next = RD_IDLE;
                end
            end
            default: rd_state_next = RD_IDLE;
        endcase
    end

    // Combinational logic for selected channel output
    always @(*) begin
        case(channel_selector)
            3'b000: selected_data = channel_data[0];
            3'b001: selected_data = channel_data[1];
            3'b010: selected_data = channel_data[2];
            3'b011: selected_data = channel_data[3];
            3'b100: selected_data = channel_data[4];
            default: selected_data = 16'h0000;
        endcase
    end

    // Synchronous reset for channel data and selector
    always @(posedge axi_aclk) begin
        if (!axi_aresetn) begin
            for (i=0; i<5; i=i+1)
                channel_data[i] <= {DATA_WIDTH{1'b0}};
            channel_selector <= 3'b000;
        end
    end

endmodule