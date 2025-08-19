//SystemVerilog
`timescale 1ns / 1ps

module nibble_rotation_shifter_axi4lite #(
    parameter ADDR_WIDTH = 4, // 16 bytes addressable space
    parameter DATA_WIDTH = 32 // AXI4-Lite standard
)(
    input wire                       clk,
    input wire                       rst_n,

    // AXI4-Lite Write Address Channel
    input wire [ADDR_WIDTH-1:0]      s_axi_awaddr,
    input wire                       s_axi_awvalid,
    output reg                       s_axi_awready,

    // AXI4-Lite Write Data Channel
    input wire [DATA_WIDTH-1:0]      s_axi_wdata,
    input wire [(DATA_WIDTH/8)-1:0]  s_axi_wstrb,
    input wire                       s_axi_wvalid,
    output reg                       s_axi_wready,

    // AXI4-Lite Write Response Channel
    output reg [1:0]                 s_axi_bresp,
    output reg                       s_axi_bvalid,
    input wire                       s_axi_bready,

    // AXI4-Lite Read Address Channel
    input wire [ADDR_WIDTH-1:0]      s_axi_araddr,
    input wire                       s_axi_arvalid,
    output reg                       s_axi_arready,

    // AXI4-Lite Read Data Channel
    output reg [DATA_WIDTH-1:0]      s_axi_rdata,
    output reg [1:0]                 s_axi_rresp,
    output reg                       s_axi_rvalid,
    input wire                       s_axi_rready
);

    // Internal registers for mapping
    reg [15:0] reg_data;
    reg [1:0]  reg_nibble_sel;
    reg [1:0]  reg_specific_nibble;
    reg [1:0]  reg_rotate_amount;

    // Internal signals for AXI handshake
    reg aw_en;

    // AXI4-Lite Write FSM
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axi_awready <= 1'b0;
            s_axi_wready  <= 1'b0;
            aw_en         <= 1'b1;
        end else begin
            if (!s_axi_awready && s_axi_awvalid && aw_en) begin
                s_axi_awready <= 1'b1;
            end else begin
                s_axi_awready <= 1'b0;
            end

            if (!s_axi_wready && s_axi_wvalid && aw_en) begin
                s_axi_wready <= 1'b1;
            end else begin
                s_axi_wready <= 1'b0;
            end

            if (s_axi_bvalid && s_axi_bready) begin
                aw_en <= 1'b1;
            end else if ((s_axi_awready && s_axi_awvalid) && (s_axi_wready && s_axi_wvalid)) begin
                aw_en <= 1'b0;
            end
        end
    end

    // Write logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reg_data            <= 16'b0;
            reg_nibble_sel      <= 2'b0;
            reg_specific_nibble <= 2'b0;
            reg_rotate_amount   <= 2'b0;
        end else begin
            if (s_axi_awready && s_axi_awvalid && s_axi_wready && s_axi_wvalid) begin
                case (s_axi_awaddr[3:2])
                    2'b00: if (s_axi_wstrb[1:0] != 2'b00)
                              reg_data <= s_axi_wdata[15:0];
                    2'b01: if (s_axi_wstrb[0])
                              reg_nibble_sel <= s_axi_wdata[1:0];
                    2'b10: if (s_axi_wstrb[0])
                              reg_specific_nibble <= s_axi_wdata[1:0];
                    2'b11: if (s_axi_wstrb[0])
                              reg_rotate_amount <= s_axi_wdata[1:0];
                    default: ;
                endcase
            end
        end
    end

    // Write response logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axi_bvalid <= 1'b0;
            s_axi_bresp  <= 2'b00;
        end else begin
            if (s_axi_awready && s_axi_awvalid && s_axi_wready && s_axi_wvalid && !s_axi_bvalid) begin
                s_axi_bvalid <= 1'b1;
                s_axi_bresp  <= 2'b00; // OKAY
            end else if (s_axi_bvalid && s_axi_bready) begin
                s_axi_bvalid <= 1'b0;
            end
        end
    end

    // AXI4-Lite Read FSM
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axi_arready <= 1'b0;
        end else begin
            if (!s_axi_arready && s_axi_arvalid) begin
                s_axi_arready <= 1'b1;
            end else begin
                s_axi_arready <= 1'b0;
            end
        end
    end

    // Read logic
    reg [15:0] reg_result_pipeline1;
    reg [15:0] reg_result_pipeline2;
    reg [3:0]  pipeline_nibble0, pipeline_nibble1, pipeline_nibble2, pipeline_nibble3;
    reg [3:0]  pipeline_rotated_nibble0, pipeline_rotated_nibble1, pipeline_rotated_nibble2, pipeline_rotated_nibble3;
    reg [1:0]  pipeline_reg_nibble_sel;
    reg [1:0]  pipeline_reg_specific_nibble;
    reg [1:0]  pipeline_reg_rotate_amount;
    reg [15:0] pipeline_reg_data;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axi_rvalid <= 1'b0;
            s_axi_rresp  <= 2'b00;
            s_axi_rdata  <= {DATA_WIDTH{1'b0}};
        end else begin
            if (s_axi_arready && s_axi_arvalid && !s_axi_rvalid) begin
                s_axi_rvalid <= 1'b1;
                s_axi_rresp  <= 2'b00; // OKAY
                case (s_axi_araddr[3:2])
                    2'b00: s_axi_rdata <= {16'b0, reg_data};
                    2'b01: s_axi_rdata <= {30'b0, reg_nibble_sel};
                    2'b10: s_axi_rdata <= {30'b0, reg_specific_nibble};
                    2'b11: s_axi_rdata <= {16'b0, reg_result_pipeline2};
                    default: s_axi_rdata <= {DATA_WIDTH{1'b0}};
                endcase
            end else if (s_axi_rvalid && s_axi_rready) begin
                s_axi_rvalid <= 1'b0;
            end
        end
    end

    // Pipeline stage 1: latch inputs for result calculation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pipeline_reg_data            <= 16'b0;
            pipeline_reg_nibble_sel      <= 2'b0;
            pipeline_reg_specific_nibble <= 2'b0;
            pipeline_reg_rotate_amount   <= 2'b0;
        end else begin
            pipeline_reg_data            <= reg_data;
            pipeline_reg_nibble_sel      <= reg_nibble_sel;
            pipeline_reg_specific_nibble <= reg_specific_nibble;
            pipeline_reg_rotate_amount   <= reg_rotate_amount;
        end
    end

    // Pipeline stage 2: extract nibbles and perform rotation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pipeline_nibble0 <= 4'b0;
            pipeline_nibble1 <= 4'b0;
            pipeline_nibble2 <= 4'b0;
            pipeline_nibble3 <= 4'b0;
            pipeline_rotated_nibble0 <= 4'b0;
            pipeline_rotated_nibble1 <= 4'b0;
            pipeline_rotated_nibble2 <= 4'b0;
            pipeline_rotated_nibble3 <= 4'b0;
        end else begin
            pipeline_nibble0 <= pipeline_reg_data[3:0];
            pipeline_nibble1 <= pipeline_reg_data[7:4];
            pipeline_nibble2 <= pipeline_reg_data[11:8];
            pipeline_nibble3 <= pipeline_reg_data[15:12];

            pipeline_rotated_nibble0 <= (pipeline_reg_rotate_amount == 2'b00) ? pipeline_reg_data[3:0] :
                                       (pipeline_reg_rotate_amount == 2'b01) ? {pipeline_reg_data[2:0], pipeline_reg_data[3]} :
                                       (pipeline_reg_rotate_amount == 2'b10) ? {pipeline_reg_data[1:0], pipeline_reg_data[3:2]} :
                                       {pipeline_reg_data[0], pipeline_reg_data[3:1]};
            pipeline_rotated_nibble1 <= (pipeline_reg_rotate_amount == 2'b00) ? pipeline_reg_data[7:4] :
                                       (pipeline_reg_rotate_amount == 2'b01) ? {pipeline_reg_data[6:4], pipeline_reg_data[7]} :
                                       (pipeline_reg_rotate_amount == 2'b10) ? {pipeline_reg_data[5:4], pipeline_reg_data[7:6]} :
                                       {pipeline_reg_data[4], pipeline_reg_data[7:5]};
            pipeline_rotated_nibble2 <= (pipeline_reg_rotate_amount == 2'b00) ? pipeline_reg_data[11:8] :
                                       (pipeline_reg_rotate_amount == 2'b01) ? {pipeline_reg_data[10:8], pipeline_reg_data[11]} :
                                       (pipeline_reg_rotate_amount == 2'b10) ? {pipeline_reg_data[9:8], pipeline_reg_data[11:10]} :
                                       {pipeline_reg_data[8], pipeline_reg_data[11:9]};
            pipeline_rotated_nibble3 <= (pipeline_reg_rotate_amount == 2'b00) ? pipeline_reg_data[15:12] :
                                       (pipeline_reg_rotate_amount == 2'b01) ? {pipeline_reg_data[14:12], pipeline_reg_data[15]} :
                                       (pipeline_reg_rotate_amount == 2'b10) ? {pipeline_reg_data[13:12], pipeline_reg_data[15:14]} :
                                       {pipeline_reg_data[12], pipeline_reg_data[15:13]};
        end
    end

    // Pipeline stage 3: result selection logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reg_result_pipeline1 <= 16'b0;
        end else begin
            case (pipeline_reg_nibble_sel)
                2'b00: reg_result_pipeline1 <= {pipeline_rotated_nibble3, pipeline_rotated_nibble2, pipeline_rotated_nibble1, pipeline_rotated_nibble0};
                2'b01: reg_result_pipeline1 <= {pipeline_rotated_nibble3, pipeline_rotated_nibble2, pipeline_nibble1, pipeline_nibble0};
                2'b10: reg_result_pipeline1 <= {pipeline_nibble3, pipeline_nibble2, pipeline_rotated_nibble1, pipeline_rotated_nibble0};
                2'b11: begin
                    case (pipeline_reg_specific_nibble)
                        2'b00: reg_result_pipeline1 <= {pipeline_nibble3, pipeline_nibble2, pipeline_nibble1, pipeline_rotated_nibble0};
                        2'b01: reg_result_pipeline1 <= {pipeline_nibble3, pipeline_nibble2, pipeline_rotated_nibble1, pipeline_nibble0};
                        2'b10: reg_result_pipeline1 <= {pipeline_nibble3, pipeline_rotated_nibble2, pipeline_nibble1, pipeline_nibble0};
                        2'b11: reg_result_pipeline1 <= {pipeline_rotated_nibble3, pipeline_nibble2, pipeline_nibble1, pipeline_nibble0};
                        default: reg_result_pipeline1 <= pipeline_reg_data;
                    endcase
                end
                default: reg_result_pipeline1 <= pipeline_reg_data;
            endcase
        end
    end

    // Pipeline stage 4: output result register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reg_result_pipeline2 <= 16'b0;
        end else begin
            reg_result_pipeline2 <= reg_result_pipeline1;
        end
    end

endmodule