//SystemVerilog
module sd_cmd_encoder (
    input  wire        clk,
    input  wire        aresetn,       // Reset signal (active low)
    
    // AXI-Stream Slave Interface
    input  wire        s_axis_tvalid, // Input valid signal
    output reg         s_axis_tready, // Ready to accept input
    input  wire [37:0] s_axis_tdata,  // Command and argument combined: {cmd[5:0], arg[31:0]}
    
    // AXI-Stream Master Interface
    output reg         m_axis_tvalid, // Output valid signal
    input  wire        m_axis_tready, // Downstream ready
    output reg         m_axis_tdata,  // Serial command output (1-bit)
    output reg         m_axis_tlast   // Indicates last bit of command
);
    
    reg [47:0] shift_reg;
    reg [5:0]  cnt;
    reg        cmd_active;
    
    // State definitions
    localparam IDLE = 2'b00;
    localparam LOAD = 2'b01;
    localparam SEND = 2'b10;
    reg [1:0]  state, next_state;
    
    // State machine
    always @(posedge clk or negedge aresetn) begin
        if (!aresetn) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end
    
    // Next state logic
    always @(*) begin
        next_state = state;
        
        case (state)
            IDLE: begin
                if (s_axis_tvalid) 
                    next_state = LOAD;
            end
            
            LOAD: begin
                next_state = SEND;
            end
            
            SEND: begin
                if (cnt == 0 && m_axis_tready)
                    next_state = IDLE;
            end
            
            default: next_state = IDLE;
        endcase
    end
    
    // Datapath logic
    always @(posedge clk or negedge aresetn) begin
        if (!aresetn) begin
            shift_reg <= 48'h0;
            cnt <= 6'd0;
            m_axis_tdata <= 1'b1; // Idle state
            m_axis_tvalid <= 1'b0;
            m_axis_tlast <= 1'b0;
            s_axis_tready <= 1'b1;
            cmd_active <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    m_axis_tdata <= 1'b1; // Idle state
                    m_axis_tvalid <= 1'b0;
                    m_axis_tlast <= 1'b0;
                    s_axis_tready <= 1'b1;
                    cmd_active <= 1'b0;
                end
                
                LOAD: begin
                    // Extract command and argument from tdata
                    shift_reg <= {1'b0, s_axis_tdata[37:32], s_axis_tdata[31:0], 7'h01};
                    cnt <= 6'd47;
                    m_axis_tdata <= 1'b0; // Start bit
                    m_axis_tvalid <= 1'b1;
                    m_axis_tlast <= 1'b0;
                    s_axis_tready <= 1'b0;
                    cmd_active <= 1'b1;
                end
                
                SEND: begin
                    if (m_axis_tready && cmd_active) begin
                        if (|cnt) begin
                            m_axis_tdata <= shift_reg[cnt];
                            cnt <= cnt - 6'd1;
                            m_axis_tlast <= (cnt == 6'd1); // Set TLAST on the last bit
                        end else begin
                            m_axis_tdata <= 1'b1; // Idle state
                            m_axis_tvalid <= 1'b0;
                            m_axis_tlast <= 1'b0;
                            s_axis_tready <= 1'b1;
                            cmd_active <= 1'b0;
                        end
                    end
                end
            endcase
        end
    end
endmodule