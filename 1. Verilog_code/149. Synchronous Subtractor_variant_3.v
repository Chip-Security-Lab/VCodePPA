module subtractor_axi_stream (
    // Clock and Reset
    input wire ACLK,
    input wire ARESETn,
    
    // AXI-Stream Input Interface
    input wire [31:0] S_AXIS_TDATA,
    input wire S_AXIS_TVALID,
    output reg S_AXIS_TREADY,
    input wire S_AXIS_TLAST,
    
    // AXI-Stream Output Interface
    output reg [31:0] M_AXIS_TDATA,
    output reg M_AXIS_TVALID,
    input wire M_AXIS_TREADY,
    output reg M_AXIS_TLAST
);

    // Internal registers
    reg [7:0] reg_a;
    reg [7:0] reg_b;
    reg [7:0] reg_res;
    
    // State machine
    reg [1:0] state;
    localparam IDLE = 2'b00;
    localparam RECEIVE_A = 2'b01;
    localparam RECEIVE_B = 2'b10;
    localparam SEND_RESULT = 2'b11;
    
    // State machine
    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            state <= IDLE;
            S_AXIS_TREADY <= 1'b0;
            M_AXIS_TVALID <= 1'b0;
            M_AXIS_TLAST <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    S_AXIS_TREADY <= 1'b1;
                    M_AXIS_TVALID <= 1'b0;
                    M_AXIS_TLAST <= 1'b0;
                    if (S_AXIS_TVALID) begin
                        reg_a <= S_AXIS_TDATA[7:0];
                        state <= RECEIVE_B;
                    end
                end
                
                RECEIVE_B: begin
                    S_AXIS_TREADY <= 1'b1;
                    if (S_AXIS_TVALID) begin
                        reg_b <= S_AXIS_TDATA[7:0];
                        state <= SEND_RESULT;
                        S_AXIS_TREADY <= 1'b0;
                    end
                end
                
                SEND_RESULT: begin
                    M_AXIS_TDATA <= {24'h0, reg_res};
                    M_AXIS_TVALID <= 1'b1;
                    M_AXIS_TLAST <= 1'b1;
                    if (M_AXIS_TREADY) begin
                        M_AXIS_TVALID <= 1'b0;
                        M_AXIS_TLAST <= 1'b0;
                        state <= IDLE;
                    end
                end
                
                default: state <= IDLE;
            endcase
        end
    end
    
    // Core logic
    always @(posedge ACLK) begin
        reg_res <= reg_a - reg_b;
    end

endmodule