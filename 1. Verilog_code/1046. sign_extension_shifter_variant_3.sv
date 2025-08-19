//SystemVerilog
module sign_extension_shifter_axi4lite #(
    parameter ADDR_WIDTH = 4,   // Enough for up to 16 registers
    parameter DATA_WIDTH = 32   // AXI4-Lite data width
)(
    input  wire                         axi_aclk,
    input  wire                         axi_aresetn,

    // AXI4-Lite Write Address Channel
    input  wire [ADDR_WIDTH-1:0]        s_axi_awaddr,
    input  wire                         s_axi_awvalid,
    output reg                          s_axi_awready,

    // AXI4-Lite Write Data Channel
    input  wire [DATA_WIDTH-1:0]        s_axi_wdata,
    input  wire [(DATA_WIDTH/8)-1:0]    s_axi_wstrb,
    input  wire                         s_axi_wvalid,
    output reg                          s_axi_wready,

    // AXI4-Lite Write Response Channel
    output reg  [1:0]                   s_axi_bresp,
    output reg                          s_axi_bvalid,
    input  wire                         s_axi_bready,

    // AXI4-Lite Read Address Channel
    input  wire [ADDR_WIDTH-1:0]        s_axi_araddr,
    input  wire                         s_axi_arvalid,
    output reg                          s_axi_arready,

    // AXI4-Lite Read Data Channel
    output reg  [DATA_WIDTH-1:0]        s_axi_rdata,
    output reg  [1:0]                   s_axi_rresp,
    output reg                          s_axi_rvalid,
    input  wire                         s_axi_rready
);

    // Register address mapping
    localparam REG_INPUT_DATA    = 4'h0;
    localparam REG_SHIFT_RIGHT   = 4'h4;
    localparam REG_SIGN_EXTEND   = 4'h8;
    localparam REG_RESULT        = 4'hC;

    // User Registers
    reg [15:0] input_data_reg;
    reg [3:0]  shift_right_reg;
    reg        sign_extend_reg;
    reg [15:0] result_reg;

    // Internal wires and registers for combinational logic
    wire sign_bit;
    wire [15:0] shifted_wire;
    wire [15:0] sign_extended_wire;
    wire [15:0] result_wire;

    assign sign_bit = input_data_reg[15];

    // Shifted version (logical shift right)
    reg [15:0] shifted_comb;
    always @(*) begin : SHIFTED_COMB
        case (shift_right_reg)
            4'd0:  shifted_comb = input_data_reg;
            4'd1:  shifted_comb = {1'b0, input_data_reg[15:1]};
            4'd2:  shifted_comb = {2'b0, input_data_reg[15:2]};
            4'd3:  shifted_comb = {3'b0, input_data_reg[15:3]};
            4'd4:  shifted_comb = {4'b0, input_data_reg[15:4]};
            4'd5:  shifted_comb = {5'b0, input_data_reg[15:5]};
            4'd6:  shifted_comb = {6'b0, input_data_reg[15:6]};
            4'd7:  shifted_comb = {7'b0, input_data_reg[15:7]};
            4'd8:  shifted_comb = {8'b0, input_data_reg[15:8]};
            4'd9:  shifted_comb = {9'b0, input_data_reg[15:9]};
            4'd10: shifted_comb = {10'b0, input_data_reg[15:10]};
            4'd11: shifted_comb = {11'b0, input_data_reg[15:11]};
            4'd12: shifted_comb = {12'b0, input_data_reg[15:12]};
            4'd13: shifted_comb = {13'b0, input_data_reg[15:13]};
            4'd14: shifted_comb = {14'b0, input_data_reg[15:14]};
            4'd15: shifted_comb = {15'b0, input_data_reg[15]};
            default: shifted_comb = input_data_reg;
        endcase
    end
    assign shifted_wire = shifted_comb;

    // Sign extended version (arithmetic shift right)
    reg [15:0] sign_extended_comb;
    always @(*) begin : SIGN_EXTENDED_COMB
        case (shift_right_reg)
            4'd0: sign_extended_comb = input_data_reg;
            4'd1: sign_extended_comb = sign_bit ? {1'b1, input_data_reg[15:1]} : {1'b0, input_data_reg[15:1]};
            4'd2: sign_extended_comb = sign_bit ? {2'b11, input_data_reg[15:2]} : {2'b00, input_data_reg[15:2]};
            4'd3: sign_extended_comb = sign_bit ? {3'b111, input_data_reg[15:3]} : {3'b000, input_data_reg[15:3]};
            4'd4: sign_extended_comb = sign_bit ? {4'b1111, input_data_reg[15:4]} : {4'b0000, input_data_reg[15:4]};
            4'd5: sign_extended_comb = sign_bit ? {5'b11111, input_data_reg[15:5]} : {5'b00000, input_data_reg[15:5]};
            4'd6: sign_extended_comb = sign_bit ? {6'b111111, input_data_reg[15:6]} : {6'b000000, input_data_reg[15:6]};
            4'd7: sign_extended_comb = sign_bit ? {7'b1111111, input_data_reg[15:7]} : {7'b0000000, input_data_reg[15:7]};
            4'd8: sign_extended_comb = sign_bit ? {8'b11111111, input_data_reg[15:8]} : {8'b00000000, input_data_reg[15:8]};
            4'd9: sign_extended_comb = sign_bit ? {9'b111111111, input_data_reg[15:9]} : {9'b000000000, input_data_reg[15:9]};
            4'd10: sign_extended_comb = sign_bit ? {10'b1111111111, input_data_reg[15:10]} : {10'b0000000000, input_data_reg[15:10]};
            4'd11: sign_extended_comb = sign_bit ? {11'b11111111111, input_data_reg[15:11]} : {11'b00000000000, input_data_reg[15:11]};
            4'd12: sign_extended_comb = sign_bit ? {12'b111111111111, input_data_reg[15:12]} : {12'b000000000000, input_data_reg[15:12]};
            4'd13: sign_extended_comb = sign_bit ? {13'b1111111111111, input_data_reg[15:13]} : {13'b0000000000000, input_data_reg[15:13]};
            4'd14: sign_extended_comb = sign_bit ? {14'b11111111111111, input_data_reg[15:14]} : {14'b00000000000000, input_data_reg[15:14]};
            4'd15: sign_extended_comb = sign_bit ? {15'b111111111111111, input_data_reg[15]} : {15'b000000000000000, input_data_reg[15]};
            default: sign_extended_comb = input_data_reg;
        endcase
    end
    assign sign_extended_wire = sign_extended_comb;

    // Select result
    assign result_wire = sign_extend_reg ? sign_extended_wire : shifted_wire;

    // Write State Machine
    reg write_active;
    always @(posedge axi_aclk) begin
        if (!axi_aresetn) begin
            s_axi_awready   <= 1'b0;
            s_axi_wready    <= 1'b0;
            s_axi_bvalid    <= 1'b0;
            s_axi_bresp     <= 2'b00;
            write_active    <= 1'b0;
        end else begin
            // Write address handshake
            if (~s_axi_awready && s_axi_awvalid && ~write_active) begin
                s_axi_awready <= 1'b1;
                write_active  <= 1'b1;
            end else begin
                s_axi_awready <= 1'b0;
            end

            // Write data handshake
            if (~s_axi_wready && s_axi_wvalid && ~write_active) begin
                s_axi_wready  <= 1'b1;
            end else begin
                s_axi_wready  <= 1'b0;
            end

            // Write response
            if (write_active && s_axi_awready && s_axi_awvalid && s_axi_wready && s_axi_wvalid) begin
                s_axi_bvalid <= 1'b1;
                s_axi_bresp  <= 2'b00; // OKAY
                write_active <= 1'b0;
            end else if (s_axi_bvalid && s_axi_bready) begin
                s_axi_bvalid <= 1'b0;
            end
        end
    end

    // Write registers
    always @(posedge axi_aclk) begin
        if (!axi_aresetn) begin
            input_data_reg   <= 16'h0;
            shift_right_reg  <= 4'h0;
            sign_extend_reg  <= 1'b0;
        end else if (s_axi_awready && s_axi_awvalid && s_axi_wready && s_axi_wvalid) begin
            case (s_axi_awaddr[ADDR_WIDTH-1:0])
                REG_INPUT_DATA: begin
                    if (s_axi_wstrb[1:0] != 0) // Only lower 16 bits
                        input_data_reg <= s_axi_wdata[15:0];
                end
                REG_SHIFT_RIGHT: begin
                    if (s_axi_wstrb[0])
                        shift_right_reg <= s_axi_wdata[3:0];
                end
                REG_SIGN_EXTEND: begin
                    if (s_axi_wstrb[0])
                        sign_extend_reg <= s_axi_wdata[0];
                end
                default: ;
            endcase
        end
    end

    // Result register update (registered for timing optimization)
    always @(posedge axi_aclk) begin
        if (!axi_aresetn) begin
            result_reg <= 16'h0;
        end else begin
            result_reg <= result_wire;
        end
    end

    // Read State Machine
    reg read_active;
    always @(posedge axi_aclk) begin
        if (!axi_aresetn) begin
            s_axi_arready <= 1'b0;
            s_axi_rvalid  <= 1'b0;
            s_axi_rresp   <= 2'b00;
            s_axi_rdata   <= {DATA_WIDTH{1'b0}};
            read_active   <= 1'b0;
        end else begin
            // Read address handshake
            if (~s_axi_arready && s_axi_arvalid && ~read_active) begin
                s_axi_arready <= 1'b1;
                read_active   <= 1'b1;
            end else begin
                s_axi_arready <= 1'b0;
            end

            // Read data
            if (read_active && s_axi_arready && s_axi_arvalid) begin
                s_axi_rvalid <= 1'b1;
                s_axi_rresp  <= 2'b00; // OKAY
                case (s_axi_araddr[ADDR_WIDTH-1:0])
                    REG_INPUT_DATA:   s_axi_rdata <= {16'h0, input_data_reg};
                    REG_SHIFT_RIGHT:  s_axi_rdata <= {28'h0, shift_right_reg};
                    REG_SIGN_EXTEND:  s_axi_rdata <= {31'h0, sign_extend_reg};
                    REG_RESULT:       s_axi_rdata <= {16'h0, result_reg};
                    default:          s_axi_rdata <= {DATA_WIDTH{1'b0}};
                endcase
                read_active <= 1'b0;
            end else if (s_axi_rvalid && s_axi_rready) begin
                s_axi_rvalid <= 1'b0;
            end
        end
    end

endmodule