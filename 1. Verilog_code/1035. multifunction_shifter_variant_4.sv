//SystemVerilog
module multifunction_shifter_axi4lite #(
    parameter ADDR_WIDTH = 4, // 16 bytes address space
    parameter DATA_WIDTH = 32
)(
    input  wire                     ACLK,
    input  wire                     ARESETN,

    // AXI4-Lite Write Address Channel
    input  wire [ADDR_WIDTH-1:0]    AWADDR,
    input  wire                     AWVALID,
    output reg                      AWREADY,

    // AXI4-Lite Write Data Channel
    input  wire [DATA_WIDTH-1:0]    WDATA,
    input  wire [(DATA_WIDTH/8)-1:0] WSTRB,
    input  wire                     WVALID,
    output reg                      WREADY,

    // AXI4-Lite Write Response Channel
    output reg [1:0]                BRESP,
    output reg                      BVALID,
    input  wire                     BREADY,

    // AXI4-Lite Read Address Channel
    input  wire [ADDR_WIDTH-1:0]    ARADDR,
    input  wire                     ARVALID,
    output reg                      ARREADY,

    // AXI4-Lite Read Data Channel
    output reg [DATA_WIDTH-1:0]     RDATA,
    output reg [1:0]                RRESP,
    output reg                      RVALID,
    input  wire                     RREADY
);

    // Register address mapping
    localparam ADDR_OPERAND   = 4'h0;
    localparam ADDR_SHIFTAMT  = 4'h4;
    localparam ADDR_OPERATION = 4'h8;
    localparam ADDR_SHIFTED   = 4'hC;

    // Internal registers
    reg [31:0] operand_reg;
    reg [4:0]  shift_amt_reg;
    reg [1:0]  operation_reg;
    reg [31:0] shifted_reg;

    // Write FSM states
    typedef enum reg [1:0] {
        WR_IDLE = 2'b00,
        WR_DATA = 2'b01,
        WR_RESP = 2'b10
    } wr_state_t;
    reg [1:0] wr_state;

    // Read FSM states
    typedef enum reg [1:0] {
        RD_IDLE = 2'b00,
        RD_DATA = 2'b01
    } rd_state_t;
    reg [1:0] rd_state;

    // Combinational signals for shifter logic
    wire [31:0] logical_stage0, logical_stage1, logical_stage2, logical_stage3, logical_stage4;
    wire [31:0] arithmetic_stage0, arithmetic_stage1, arithmetic_stage2, arithmetic_stage3, arithmetic_stage4;
    wire [31:0] rotate_stage0, rotate_stage1, rotate_stage2, rotate_stage3, rotate_stage4;
    wire [63:0] double_operand;
    wire        sign_bit;

    // Logical right shift (barrel shifter)
    assign logical_stage0 = shift_amt_reg[0] ? {1'b0, operand_reg[31:1]} : operand_reg;
    assign logical_stage1 = shift_amt_reg[1] ? {2'b0, logical_stage0[31:2]} : logical_stage0;
    assign logical_stage2 = shift_amt_reg[2] ? {4'b0, logical_stage1[31:4]} : logical_stage1;
    assign logical_stage3 = shift_amt_reg[3] ? {8'b0, logical_stage2[31:8]} : logical_stage2;
    assign logical_stage4 = shift_amt_reg[4] ? {16'b0, logical_stage3[31:16]} : logical_stage3;

    // Arithmetic right shift (barrel shifter)
    assign sign_bit = operand_reg[31];
    assign arithmetic_stage0 = shift_amt_reg[0] ? {sign_bit, operand_reg[31:1]} : operand_reg;
    assign arithmetic_stage1 = shift_amt_reg[1] ? {{2{sign_bit}}, arithmetic_stage0[31:2]} : arithmetic_stage0;
    assign arithmetic_stage2 = shift_amt_reg[2] ? {{4{sign_bit}}, arithmetic_stage1[31:4]} : arithmetic_stage1;
    assign arithmetic_stage3 = shift_amt_reg[3] ? {{8{sign_bit}}, arithmetic_stage2[31:8]} : arithmetic_stage2;
    assign arithmetic_stage4 = shift_amt_reg[4] ? {{16{sign_bit}}, arithmetic_stage3[31:16]} : arithmetic_stage3;

    // Rotate right (barrel shifter)
    assign double_operand = {operand_reg, operand_reg};
    assign rotate_stage0 = shift_amt_reg[0] ? (double_operand[31:0] >> 1 | double_operand[63:32] << 31) : double_operand[31:0];
    assign rotate_stage1 = shift_amt_reg[1] ? (rotate_stage0 >> 2  | rotate_stage0 << 30) : rotate_stage0;
    assign rotate_stage2 = shift_amt_reg[2] ? (rotate_stage1 >> 4  | rotate_stage1 << 28) : rotate_stage1;
    assign rotate_stage3 = shift_amt_reg[3] ? (rotate_stage2 >> 8  | rotate_stage2 << 24) : rotate_stage2;
    assign rotate_stage4 = shift_amt_reg[4] ? (rotate_stage3 >> 16 | rotate_stage3 << 16) : rotate_stage3;

    // Update shifted_reg combinationally
    always @(*) begin
        case (operation_reg)
            2'b00: shifted_reg = logical_stage4; // Logical right
            2'b01: shifted_reg = arithmetic_stage4; // Arithmetic right
            2'b10: shifted_reg = rotate_stage4; // Rotate right
            2'b11: shifted_reg = {operand_reg[15:0], operand_reg[31:16]}; // Byte swap
            default: shifted_reg = 32'b0;
        endcase
    end

    // Write FSM
    always @(posedge ACLK or negedge ARESETN) begin
        if (!ARESETN) begin
            wr_state      <= WR_IDLE;
            AWREADY       <= 1'b0;
            WREADY        <= 1'b0;
            BVALID        <= 1'b0;
            BRESP         <= 2'b00;
            operand_reg   <= 32'b0;
            shift_amt_reg <= 5'b0;
            operation_reg <= 2'b0;
        end else begin
            case (wr_state)
                WR_IDLE: begin
                    AWREADY <= 1'b1;
                    WREADY  <= 1'b0;
                    BVALID  <= 1'b0;
                    if (AWVALID && AWREADY) begin
                        wr_state <= WR_DATA;
                        AWREADY  <= 1'b0;
                        WREADY   <= 1'b1;
                    end
                end
                WR_DATA: begin
                    if (WVALID && WREADY) begin
                        // Write decode
                        case (AWADDR[ADDR_WIDTH-1:0])
                            ADDR_OPERAND: begin
                                if (WSTRB[0]) operand_reg[7:0]   <= WDATA[7:0];
                                if (WSTRB[1]) operand_reg[15:8]  <= WDATA[15:8];
                                if (WSTRB[2]) operand_reg[23:16] <= WDATA[23:16];
                                if (WSTRB[3]) operand_reg[31:24] <= WDATA[31:24];
                            end
                            ADDR_SHIFTAMT: begin
                                if (WSTRB[0]) shift_amt_reg <= WDATA[4:0];
                            end
                            ADDR_OPERATION: begin
                                if (WSTRB[0]) operation_reg <= WDATA[1:0];
                            end
                            default: ;
                        endcase
                        WREADY  <= 1'b0;
                        BVALID  <= 1'b1;
                        BRESP   <= 2'b00; // OKAY response
                        wr_state <= WR_RESP;
                    end
                end
                WR_RESP: begin
                    if (BREADY && BVALID) begin
                        BVALID  <= 1'b0;
                        wr_state <= WR_IDLE;
                    end
                end
                default: wr_state <= WR_IDLE;
            endcase
            if (!AWVALID) AWREADY <= 1'b1;
            if (!WVALID)  WREADY  <= 1'b1;
        end
    end

    // Read FSM
    always @(posedge ACLK or negedge ARESETN) begin
        if (!ARESETN) begin
            rd_state <= RD_IDLE;
            ARREADY  <= 1'b0;
            RVALID   <= 1'b0;
            RDATA    <= 32'b0;
            RRESP    <= 2'b00;
        end else begin
            case (rd_state)
                RD_IDLE: begin
                    ARREADY <= 1'b1;
                    RVALID  <= 1'b0;
                    if (ARVALID && ARREADY) begin
                        ARREADY <= 1'b0;
                        // Read decode
                        case (ARADDR[ADDR_WIDTH-1:0])
                            ADDR_OPERAND:   RDATA <= operand_reg;
                            ADDR_SHIFTAMT:  RDATA <= {27'b0, shift_amt_reg};
                            ADDR_OPERATION: RDATA <= {30'b0, operation_reg};
                            ADDR_SHIFTED:   RDATA <= shifted_reg;
                            default:        RDATA <= 32'b0;
                        endcase
                        RRESP   <= 2'b00; // OKAY response
                        RVALID  <= 1'b1;
                        rd_state <= RD_DATA;
                    end
                end
                RD_DATA: begin
                    if (RREADY && RVALID) begin
                        RVALID  <= 1'b0;
                        rd_state <= RD_IDLE;
                    end
                end
                default: rd_state <= RD_IDLE;
            endcase
            if (!ARVALID) ARREADY <= 1'b1;
        end
    end

endmodule