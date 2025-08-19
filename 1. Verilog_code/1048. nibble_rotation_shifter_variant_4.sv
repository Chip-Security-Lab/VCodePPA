//SystemVerilog
module axi4lite_nibble_rotation_shifter #(
    parameter ADDR_WIDTH = 4,    // 16B addressable space
    parameter DATA_WIDTH = 16    // AXI4-Lite 16-bit data bus
)(
    // AXI4-Lite clock and reset
    input                   ACLK,
    input                   ARESETN,
    // AXI4-Lite Write Address Channel
    input  [ADDR_WIDTH-1:0] AWADDR,
    input                   AWVALID,
    output reg              AWREADY,
    // AXI4-Lite Write Data Channel
    input  [DATA_WIDTH-1:0] WDATA,
    input  [(DATA_WIDTH/8)-1:0] WSTRB,
    input                   WVALID,
    output reg              WREADY,
    // AXI4-Lite Write Response Channel
    output reg [1:0]        BRESP,
    output reg              BVALID,
    input                   BREADY,
    // AXI4-Lite Read Address Channel
    input  [ADDR_WIDTH-1:0] ARADDR,
    input                   ARVALID,
    output reg              ARREADY,
    // AXI4-Lite Read Data Channel
    output reg [DATA_WIDTH-1:0] RDATA,
    output reg [1:0]        RRESP,
    output reg              RVALID,
    input                   RREADY
);

    // Register map
    // 0x0 : DATA         [15:0]   RW
    // 0x2 : NIBBLE_SEL   [1:0]    RW
    // 0x4 : SPEC_NIBBLE  [1:0]    RW
    // 0x6 : ROTATE_AMT   [1:0]    RW
    // 0x8 : RESULT       [15:0]   RO

    // Internal registers
    reg [15:0] reg_data;
    reg [1:0]  reg_nibble_sel;
    reg [1:0]  reg_specific_nibble;
    reg [1:0]  reg_rotate_amount;
    reg [15:0] reg_result_stage3; // Final result after pipeline

    // AXI Write FSM
    reg        aw_en;
    reg [ADDR_WIDTH-1:0] awaddr_reg;

    always @(posedge ACLK) begin
        if (!ARESETN) begin
            AWREADY <= 1'b0;
            aw_en   <= 1'b1;
            awaddr_reg <= {ADDR_WIDTH{1'b0}};
        end else begin
            if (!AWREADY && AWVALID && aw_en) begin
                AWREADY <= 1'b1;
                awaddr_reg <= AWADDR;
                aw_en <= 1'b0;
            end else if (WREADY && WVALID) begin
                AWREADY <= 1'b0;
            end
        end
    end

    // AXI Write Data Channel
    always @(posedge ACLK) begin
        if (!ARESETN) begin
            WREADY <= 1'b0;
        end else begin
            if (!WREADY && AWREADY && AWVALID && WVALID) begin
                WREADY <= 1'b1;
            end else begin
                WREADY <= 1'b0;
            end
        end
    end

    // AXI Write Response Channel
    always @(posedge ACLK) begin
        if (!ARESETN) begin
            BVALID <= 1'b0;
            BRESP  <= 2'b00;
        end else begin
            if (AWREADY && AWVALID && WREADY && WVALID && !BVALID) begin
                BVALID <= 1'b1;
                BRESP  <= 2'b00;
            end else if (BVALID && BREADY) begin
                BVALID <= 1'b0;
            end
        end
    end

    // Register write logic, supports byte enables
    always @(posedge ACLK) begin
        if (!ARESETN) begin
            reg_data           <= 16'b0;
            reg_nibble_sel     <= 2'b0;
            reg_specific_nibble<= 2'b0;
            reg_rotate_amount  <= 2'b0;
        end else if (AWREADY && AWVALID && WREADY && WVALID) begin
            case (awaddr_reg[ADDR_WIDTH-1:1])
                3'b000: begin // 0x0 DATA
                    if (WSTRB[1]) reg_data[15:8] <= WDATA[15:8];
                    if (WSTRB[0]) reg_data[7:0]  <= WDATA[7:0];
                end
                3'b001: begin // 0x2 NIBBLE_SEL
                    if (WSTRB[0]) reg_nibble_sel <= WDATA[1:0];
                end
                3'b010: begin // 0x4 SPEC_NIBBLE
                    if (WSTRB[0]) reg_specific_nibble <= WDATA[1:0];
                end
                3'b011: begin // 0x6 ROTATE_AMT
                    if (WSTRB[0]) reg_rotate_amount <= WDATA[1:0];
                end
                default: ;
            endcase
        end
    end

    // AXI Read FSM
    reg [ADDR_WIDTH-1:0] araddr_reg;

    always @(posedge ACLK) begin
        if (!ARESETN) begin
            ARREADY <= 1'b0;
            araddr_reg <= {ADDR_WIDTH{1'b0}};
        end else begin
            if (!ARREADY && ARVALID) begin
                ARREADY <= 1'b1;
                araddr_reg <= ARADDR;
            end else begin
                ARREADY <= 1'b0;
            end
        end
    end

    // ---------------- Pipeline for nibble rotation and result logic ----------------

    // Pipeline Stage 1: Latch inputs for rotation
    reg [3:0] nibble0_stage1, nibble1_stage1, nibble2_stage1, nibble3_stage1;
    reg [1:0] rotate_amount_stage1, nibble_sel_stage1, specific_nibble_stage1;
    reg [15:0] reg_data_stage1;

    always @(posedge ACLK) begin
        if (!ARESETN) begin
            nibble0_stage1 <= 4'b0;
            nibble1_stage1 <= 4'b0;
            nibble2_stage1 <= 4'b0;
            nibble3_stage1 <= 4'b0;
            rotate_amount_stage1 <= 2'b0;
            nibble_sel_stage1 <= 2'b0;
            specific_nibble_stage1 <= 2'b0;
            reg_data_stage1 <= 16'b0;
        end else begin
            nibble0_stage1 <= reg_data[3:0];
            nibble1_stage1 <= reg_data[7:4];
            nibble2_stage1 <= reg_data[11:8];
            nibble3_stage1 <= reg_data[15:12];
            rotate_amount_stage1 <= reg_rotate_amount;
            nibble_sel_stage1 <= reg_nibble_sel;
            specific_nibble_stage1 <= reg_specific_nibble;
            reg_data_stage1 <= reg_data;
        end
    end

    // Pipeline Stage 2: Rotate each nibble (one pipeline stage for all nibbles)
    reg [3:0] rotated_nibble0_stage2, rotated_nibble1_stage2, rotated_nibble2_stage2, rotated_nibble3_stage2;
    reg [1:0] nibble_sel_stage2, specific_nibble_stage2;
    reg [15:0] reg_data_stage2;

    always @(posedge ACLK) begin
        if (!ARESETN) begin
            rotated_nibble0_stage2 <= 4'b0;
            rotated_nibble1_stage2 <= 4'b0;
            rotated_nibble2_stage2 <= 4'b0;
            rotated_nibble3_stage2 <= 4'b0;
            nibble_sel_stage2 <= 2'b0;
            specific_nibble_stage2 <= 2'b0;
            reg_data_stage2 <= 16'b0;
        end else begin
            // Rotate nibble0
            case (rotate_amount_stage1)
                2'b00: rotated_nibble0_stage2 <= nibble0_stage1;
                2'b01: rotated_nibble0_stage2 <= {nibble0_stage1[2:0], nibble0_stage1[3]};
                2'b10: rotated_nibble0_stage2 <= {nibble0_stage1[1:0], nibble0_stage1[3:2]};
                2'b11: rotated_nibble0_stage2 <= {nibble0_stage1[0], nibble0_stage1[3:1]};
                default: rotated_nibble0_stage2 <= nibble0_stage1;
            endcase
            // Rotate nibble1
            case (rotate_amount_stage1)
                2'b00: rotated_nibble1_stage2 <= nibble1_stage1;
                2'b01: rotated_nibble1_stage2 <= {nibble1_stage1[2:0], nibble1_stage1[3]};
                2'b10: rotated_nibble1_stage2 <= {nibble1_stage1[1:0], nibble1_stage1[3:2]};
                2'b11: rotated_nibble1_stage2 <= {nibble1_stage1[0], nibble1_stage1[3:1]};
                default: rotated_nibble1_stage2 <= nibble1_stage1;
            endcase
            // Rotate nibble2
            case (rotate_amount_stage1)
                2'b00: rotated_nibble2_stage2 <= nibble2_stage1;
                2'b01: rotated_nibble2_stage2 <= {nibble2_stage1[2:0], nibble2_stage1[3]};
                2'b10: rotated_nibble2_stage2 <= {nibble2_stage1[1:0], nibble2_stage1[3:2]};
                2'b11: rotated_nibble2_stage2 <= {nibble2_stage1[0], nibble2_stage1[3:1]};
                default: rotated_nibble2_stage2 <= nibble2_stage1;
            endcase
            // Rotate nibble3
            case (rotate_amount_stage1)
                2'b00: rotated_nibble3_stage2 <= nibble3_stage1;
                2'b01: rotated_nibble3_stage2 <= {nibble3_stage1[2:0], nibble3_stage1[3]};
                2'b10: rotated_nibble3_stage2 <= {nibble3_stage1[1:0], nibble3_stage1[3:2]};
                2'b11: rotated_nibble3_stage2 <= {nibble3_stage1[0], nibble3_stage1[3:1]};
                default: rotated_nibble3_stage2 <= nibble3_stage1;
            endcase

            nibble_sel_stage2 <= nibble_sel_stage1;
            specific_nibble_stage2 <= specific_nibble_stage1;
            reg_data_stage2 <= reg_data_stage1;
        end
    end

    // Pipeline Stage 3: Select and assemble result
    always @(posedge ACLK) begin
        if (!ARESETN) begin
            reg_result_stage3 <= 16'b0;
        end else begin
            case (nibble_sel_stage2)
                2'b00: reg_result_stage3 <= {rotated_nibble3_stage2, rotated_nibble2_stage2, rotated_nibble1_stage2, rotated_nibble0_stage2};
                2'b01: reg_result_stage3 <= {rotated_nibble3_stage2, rotated_nibble2_stage2, nibble1_stage1, nibble0_stage1};
                2'b10: reg_result_stage3 <= {nibble3_stage1, nibble2_stage1, rotated_nibble1_stage2, rotated_nibble0_stage2};
                2'b11: begin
                    case (specific_nibble_stage2)
                        2'b00: reg_result_stage3 <= {nibble3_stage1, nibble2_stage1, nibble1_stage1, rotated_nibble0_stage2};
                        2'b01: reg_result_stage3 <= {nibble3_stage1, nibble2_stage1, rotated_nibble1_stage2, nibble0_stage1};
                        2'b10: reg_result_stage3 <= {nibble3_stage1, rotated_nibble2_stage2, nibble1_stage1, nibble0_stage1};
                        2'b11: reg_result_stage3 <= {rotated_nibble3_stage2, nibble2_stage1, nibble1_stage1, nibble0_stage1};
                        default: reg_result_stage3 <= reg_data_stage2;
                    endcase
                end
                default: reg_result_stage3 <= reg_data_stage2;
            endcase
        end
    end

    // ---------------- AXI Read Data Path ----------------
    always @(posedge ACLK) begin
        if (!ARESETN) begin
            RVALID <= 1'b0;
            RDATA  <= {DATA_WIDTH{1'b0}};
            RRESP  <= 2'b00;
        end else begin
            if (ARREADY && ARVALID && !RVALID) begin
                RVALID <= 1'b1;
                RRESP  <= 2'b00;
                case (araddr_reg[ADDR_WIDTH-1:1])
                    3'b000: RDATA <= reg_data;            // 0x0 DATA
                    3'b001: RDATA <= {14'b0, reg_nibble_sel}; // 0x2 NIBBLE_SEL
                    3'b010: RDATA <= {14'b0, reg_specific_nibble}; // 0x4 SPEC_NIBBLE
                    3'b011: RDATA <= {14'b0, reg_rotate_amount}; // 0x6 ROTATE_AMT
                    3'b100: RDATA <= reg_result_stage3;           // 0x8 RESULT (read-only, pipelined)
                    default: RDATA <= {DATA_WIDTH{1'b0}};
                endcase
            end else if (RVALID && RREADY) begin
                RVALID <= 1'b0;
            end
        end
    end

endmodule