//SystemVerilog
//IEEE 1364-2005 Verilog
module mac_rx_ctrl #(
    parameter MIN_FRAME_SIZE = 64,
    parameter MAX_FRAME_SIZE = 1522
)(
    input rx_clk,
    input sys_clk,
    input rst_n,
    input [7:0] phy_data,
    input data_valid,
    input crc_error,
    output [31:0] pkt_data,
    output pkt_valid,
    output [15:0] pkt_length,
    output rx_error
);
    // State encoding parameters
    localparam IDLE = 3'b000;
    localparam PREAMBLE = 3'b001;
    localparam SFD = 3'b010;
    localparam DATA = 3'b011;
    localparam FCS = 3'b100;
    localparam INTERFRAME = 3'b101;
    
    // Internal signals
    wire [2:0] next_state;
    reg [2:0] state;
    reg [15:0] byte_count;
    reg [31:0] crc_result;
    reg [7:0] sync_phy_data;
    reg sync_data_valid;
    reg [31:0] pkt_data_reg;
    reg pkt_valid_reg;
    reg [15:0] pkt_length_reg;
    reg rx_error_reg;
    
    // Output assignments
    assign pkt_data = pkt_data_reg;
    assign pkt_valid = pkt_valid_reg;
    assign pkt_length = pkt_length_reg;
    assign rx_error = rx_error_reg;
    
    // Instantiate combinational logic module
    mac_rx_ctrl_comb u_mac_rx_ctrl_comb (
        .state(state),
        .sync_data_valid(sync_data_valid),
        .sync_phy_data(sync_phy_data),
        .byte_count(byte_count),
        .MAX_FRAME_SIZE(MAX_FRAME_SIZE),
        .next_state(next_state)
    );
    
    // Clock domain crossing synchronizer (sequential logic)
    always @(posedge sys_clk or negedge rst_n) begin
        if (!rst_n) begin
            sync_phy_data <= 8'h0;
            sync_data_valid <= 1'b0;
        end else begin
            sync_phy_data <= phy_data;
            sync_data_valid <= data_valid;
        end
    end

    // State and data registers (sequential logic)
    always @(posedge sys_clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            byte_count <= 16'd0;
            pkt_valid_reg <= 1'b0;
            pkt_length_reg <= 16'd0;
            rx_error_reg <= 1'b0;
            crc_result <= 32'h0;
            pkt_data_reg <= 32'h0;
        end else begin
            state <= next_state;
            
            // Byte counter logic
            case(state)
                PREAMBLE: begin
                    byte_count <= (byte_count < 7) ? byte_count + 1'b1 : 16'd0;
                end
                
                DATA: begin   
                    byte_count <= byte_count + 1'b1;
                    // Data assembly
                    pkt_data_reg <= {pkt_data_reg[23:0], sync_phy_data};
                    
                    // Packet length tracking
                    if (byte_count == 16'd0) begin
                        pkt_length_reg <= 16'd1;
                    end else begin
                        pkt_length_reg <= pkt_length_reg + 1'b1;
                    end
                end
                
                default: begin
                    byte_count <= 16'd0;
                end
            endcase
            
            // Packet validation and error detection
            if (state == DATA && next_state == FCS) begin
                pkt_valid_reg <= 1'b1;
                // CRC error checking
                if (crc_error) begin
                    rx_error_reg <= 1'b1;
                end
            end else if (next_state == IDLE) begin
                pkt_valid_reg <= 1'b0;
                rx_error_reg <= 1'b0;
            end
        end
    end
endmodule

// Combinational logic module for next state determination
module mac_rx_ctrl_comb (
    input [2:0] state,
    input sync_data_valid,
    input [7:0] sync_phy_data,
    input [15:0] byte_count,
    input [15:0] MAX_FRAME_SIZE,
    output reg [2:0] next_state
);
    // State encoding parameters
    localparam IDLE = 3'b000;
    localparam PREAMBLE = 3'b001;
    localparam SFD = 3'b010;
    localparam DATA = 3'b011;
    localparam FCS = 3'b100;
    localparam INTERFRAME = 3'b101;
    
    // Pure combinational next-state logic
    always @(*) begin
        next_state = state; // Default: maintain current state
        
        case(state)
            IDLE: begin
                if (sync_data_valid && sync_phy_data == 8'h55) 
                    next_state = PREAMBLE;
            end
            
            PREAMBLE: begin
                if (sync_phy_data == 8'hD5) 
                    next_state = SFD;
            end
            
            SFD: begin
                next_state = DATA;
            end
            
            DATA: begin
                if (!sync_data_valid || byte_count >= MAX_FRAME_SIZE) 
                    next_state = FCS;
            end
            
            FCS: begin
                next_state = INTERFRAME;
            end
            
            INTERFRAME: begin
                if (sync_data_valid) 
                    next_state = PREAMBLE;
                else
                    next_state = IDLE;
            end
            
            default: begin
                next_state = IDLE;
            end
        endcase
    end
endmodule