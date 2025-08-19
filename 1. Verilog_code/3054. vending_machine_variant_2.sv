//SystemVerilog
module vending_machine_axi_lite (
    // Global signals
    input wire ACLK,
    input wire ARESETn,
    
    // Write Address Channel
    input wire [31:0] AWADDR,
    input wire AWVALID,
    output reg AWREADY,
    
    // Write Data Channel
    input wire [31:0] WDATA,
    input wire [3:0] WSTRB,
    input wire WVALID,
    output reg WREADY,
    
    // Write Response Channel
    output reg [1:0] BRESP,
    output reg BVALID,
    input wire BREADY,
    
    // Read Address Channel
    input wire [31:0] ARADDR,
    input wire ARVALID,
    output reg ARREADY,
    
    // Read Data Channel
    output reg [31:0] RDATA,
    output reg [1:0] RRESP,
    output reg RVALID,
    input wire RREADY
);

    // Internal registers
    reg [1:0] coin_reg;
    reg dispense_reg;
    reg [4:0] state, next_state;
    
    // Address decoding
    localparam COIN_ADDR = 32'h00000000;
    localparam DISPENSE_ADDR = 32'h00000004;
    localparam STATE_ADDR = 32'h00000008;
    
    // Write FSM
    reg [1:0] write_state;
    localparam WRITE_IDLE = 2'b00;
    localparam WRITE_ADDR = 2'b01;
    localparam WRITE_DATA = 2'b10;
    localparam WRITE_RESP = 2'b11;
    
    // Read FSM
    reg [1:0] read_state;
    localparam READ_IDLE = 2'b00;
    localparam READ_ADDR = 2'b01;
    localparam READ_DATA = 2'b10;
    
    // Karatsuba multiplier signals
    wire [31:0] karatsuba_result;
    reg [31:0] a_reg, b_reg;
    reg karatsuba_start;
    wire karatsuba_done;
    
    // Karatsuba multiplier instance
    karatsuba_multiplier_32bit u_karatsuba (
        .clk(ACLK),
        .rst_n(ARESETn),
        .a(a_reg),
        .b(b_reg),
        .start(karatsuba_start),
        .result(karatsuba_result),
        .done(karatsuba_done)
    );
    
    // Write FSM
    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            write_state <= WRITE_IDLE;
            AWREADY <= 1'b0;
            WREADY <= 1'b0;
            BVALID <= 1'b0;
            BRESP <= 2'b00;
            coin_reg <= 2'b00;
            a_reg <= 32'b0;
            b_reg <= 32'b0;
            karatsuba_start <= 1'b0;
        end else begin
            case (write_state)
                WRITE_IDLE: begin
                    AWREADY <= 1'b1;
                    if (AWVALID) begin
                        write_state <= WRITE_ADDR;
                        AWREADY <= 1'b0;
                    end
                end
                
                WRITE_ADDR: begin
                    WREADY <= 1'b1;
                    if (WVALID) begin
                        write_state <= WRITE_DATA;
                        WREADY <= 1'b0;
                        if (AWADDR == COIN_ADDR) begin
                            coin_reg <= WDATA[1:0];
                            // Initialize Karatsuba multiplier
                            a_reg <= {30'b0, WDATA[1:0]};
                            b_reg <= 32'd5; // Multiplier for state calculation
                            karatsuba_start <= 1'b1;
                        end
                    end
                end
                
                WRITE_DATA: begin
                    BVALID <= 1'b1;
                    BRESP <= 2'b00;
                    if (BREADY) begin
                        write_state <= WRITE_IDLE;
                        BVALID <= 1'b0;
                        karatsuba_start <= 1'b0;
                    end
                end
                
                default: write_state <= WRITE_IDLE;
            endcase
        end
    end
    
    // Read FSM
    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            read_state <= READ_IDLE;
            ARREADY <= 1'b0;
            RVALID <= 1'b0;
            RRESP <= 2'b00;
            RDATA <= 32'b0;
        end else begin
            case (read_state)
                READ_IDLE: begin
                    ARREADY <= 1'b1;
                    if (ARVALID) begin
                        read_state <= READ_ADDR;
                        ARREADY <= 1'b0;
                    end
                end
                
                READ_ADDR: begin
                    RVALID <= 1'b1;
                    RRESP <= 2'b00;
                    case (ARADDR)
                        COIN_ADDR: RDATA <= {30'b0, coin_reg};
                        DISPENSE_ADDR: RDATA <= {31'b0, dispense_reg};
                        STATE_ADDR: RDATA <= {27'b0, state};
                        default: RDATA <= 32'b0;
                    endcase
                    if (RREADY) begin
                        read_state <= READ_IDLE;
                        RVALID <= 1'b0;
                    end
                end
                
                default: read_state <= READ_IDLE;
            endcase
        end
    end
    
    // Main state machine with Karatsuba multiplier
    always @(posedge ACLK or negedge ARESETn)
        if (!ARESETn) state <= 5'd0;
        else state <= next_state;
    
    always @(*) begin
        dispense_reg = 1'b0;
        casez ({state, coin_reg})
            {5'd0, 2'b01}: next_state = karatsuba_result[4:0];
            {5'd0, 2'b10}: next_state = 5'd10;
            {5'd0, 2'b11}: next_state = 5'd25;
            {5'd5, 2'b01}: next_state = 5'd10;
            {5'd5, 2'b10}: next_state = 5'd15;
            {5'd5, 2'b11}: next_state = 5'd30;
            {5'd10, 2'b01}: next_state = 5'd15;
            {5'd10, 2'b10}: next_state = 5'd20;
            {5'd10, 2'b11}: next_state = 5'd0;
            {5'd15, 2'b01}: next_state = 5'd20;
            {5'd15, 2'b10}: next_state = 5'd25;
            {5'd15, 2'b11}: next_state = 5'd0;
            {5'd20, 2'b??}: next_state = 5'd0;
            {5'd25, 2'b??}: next_state = 5'd0;
            {5'd30, 2'b??}: next_state = 5'd0;
            default: next_state = state;
        endcase
        if ((state >= 5'd20 && state < 5'd30 && coin_reg != 2'b00) ||
            (state >= 5'd30)) dispense_reg = 1'b1;
    end
    
endmodule

// Karatsuba multiplier module
module karatsuba_multiplier_32bit (
    input wire clk,
    input wire rst_n,
    input wire [31:0] a,
    input wire [31:0] b,
    input wire start,
    output reg [31:0] result,
    output reg done
);
    
    // Internal signals
    reg [31:0] a_reg, b_reg;
    reg [31:0] ah, al, bh, bl;
    reg [31:0] z0, z1, z2;
    reg [2:0] state;
    localparam IDLE = 3'b000;
    localparam SPLIT = 3'b001;
    localparam MULT1 = 3'b010;
    localparam MULT2 = 3'b011;
    localparam MULT3 = 3'b100;
    localparam COMBINE = 3'b101;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            result <= 32'b0;
            done <= 1'b0;
            a_reg <= 32'b0;
            b_reg <= 32'b0;
            ah <= 32'b0;
            al <= 32'b0;
            bh <= 32'b0;
            bl <= 32'b0;
            z0 <= 32'b0;
            z1 <= 32'b0;
            z2 <= 32'b0;
        end else begin
            case (state)
                IDLE: begin
                    done <= 1'b0;
                    if (start) begin
                        a_reg <= a;
                        b_reg <= b;
                        state <= SPLIT;
                    end
                end
                
                SPLIT: begin
                    ah <= a_reg[31:16];
                    al <= a_reg[15:0];
                    bh <= b_reg[31:16];
                    bl <= b_reg[15:0];
                    state <= MULT1;
                end
                
                MULT1: begin
                    z0 <= al * bl;
                    state <= MULT2;
                end
                
                MULT2: begin
                    z1 <= (al + ah) * (bl + bh);
                    state <= MULT3;
                end
                
                MULT3: begin
                    z2 <= ah * bh;
                    state <= COMBINE;
                end
                
                COMBINE: begin
                    result <= (z2 << 32) + ((z1 - z2 - z0) << 16) + z0;
                    done <= 1'b1;
                    state <= IDLE;
                end
                
                default: state <= IDLE;
            endcase
        end
    end
    
endmodule