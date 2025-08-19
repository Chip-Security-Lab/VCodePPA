//SystemVerilog
module reset_monitor (
    // Clock and Reset
    input  wire        aclk,
    input  wire        aresetn,
    
    // AXI-Stream Input Interface
    input  wire [31:0] s_axis_tdata,
    input  wire        s_axis_tvalid,
    output wire        s_axis_tready,
    input  wire        s_axis_tlast,
    
    // AXI-Stream Output Interface
    output reg  [31:0] m_axis_tdata,
    output reg         m_axis_tvalid,
    input  wire        m_axis_tready,
    output reg         m_axis_tlast,
    
    // Original module I/O
    input  wire [3:0]  reset_inputs,
    output wire [3:0]  reset_outputs,
    output wire [3:0]  reset_status
);

    // Internal registers
    reg [3:0] reset_outputs_reg;
    reg [3:0] reset_status_reg;
    
    // Register addresses
    localparam RESET_OUTPUTS_ADDR = 4'h0;
    localparam RESET_STATUS_ADDR  = 4'h4;
    
    // Command types
    localparam CMD_READ  = 8'h01;
    localparam CMD_WRITE = 8'h02;
    
    // Stream protocol states
    localparam ST_IDLE     = 2'b00;
    localparam ST_CMD      = 2'b01;
    localparam ST_PROCESS  = 2'b10;
    localparam ST_RESPONSE = 2'b11;
    
    // Stream state and command registers
    reg [1:0]  stream_state;
    reg [7:0]  cmd_type;
    reg [31:0] cmd_addr;
    reg [31:0] cmd_data;
    
    // Stream handshaking
    reg s_axis_tready_reg;
    assign s_axis_tready = s_axis_tready_reg;
    
    // Original functionality
    always @(posedge aclk) begin
        if (!aresetn) begin
            reset_outputs_reg <= 4'b0;
            reset_status_reg <= 4'b0;
        end else begin
            reset_outputs_reg <= reset_inputs;
            reset_status_reg <= reset_inputs;  // Track which resets were activated
        end
    end
    
    assign reset_outputs = reset_outputs_reg;
    assign reset_status = reset_status_reg;
    
    // AXI-Stream protocol handling
    always @(posedge aclk) begin
        if (!aresetn) begin
            stream_state <= ST_IDLE;
            s_axis_tready_reg <= 1'b0;
            m_axis_tvalid <= 1'b0;
            m_axis_tdata <= 32'b0;
            m_axis_tlast <= 1'b0;
            cmd_type <= 8'b0;
            cmd_addr <= 32'b0;
            cmd_data <= 32'b0;
        end else begin
            case (stream_state)
                ST_IDLE: begin
                    s_axis_tready_reg <= 1'b1;
                    m_axis_tvalid <= 1'b0;
                    
                    if (s_axis_tvalid && s_axis_tready) begin
                        cmd_type <= s_axis_tdata[7:0];    // First byte contains command type
                        cmd_addr <= s_axis_tdata[31:8];   // Remaining bits for address
                        s_axis_tready_reg <= s_axis_tlast ? 1'b0 : 1'b1; // If not last, keep accepting
                        
                        if (s_axis_tlast) begin
                            stream_state <= ST_PROCESS;
                        end else begin
                            stream_state <= ST_CMD;
                        end
                    end
                end
                
                ST_CMD: begin
                    if (s_axis_tvalid && s_axis_tready) begin
                        cmd_data <= s_axis_tdata;        // Get data for write commands
                        s_axis_tready_reg <= 1'b0;       // Stop accepting data
                        
                        if (s_axis_tlast) begin
                            stream_state <= ST_PROCESS;
                        end
                    end
                end
                
                ST_PROCESS: begin
                    // Process the command
                    m_axis_tvalid <= 1'b1;
                    m_axis_tlast <= 1'b1;
                    
                    case (cmd_type)
                        CMD_READ: begin
                            case (cmd_addr[3:0])
                                RESET_OUTPUTS_ADDR: begin
                                    m_axis_tdata <= {28'b0, reset_outputs_reg};
                                end
                                
                                RESET_STATUS_ADDR: begin
                                    m_axis_tdata <= {28'b0, reset_status_reg};
                                end
                                
                                default: begin
                                    m_axis_tdata <= 32'hFFFFFFFF; // Error indication
                                end
                            endcase
                        end
                        
                        CMD_WRITE: begin
                            // Write operations - all registers are read-only in this design
                            // Return status code
                            m_axis_tdata <= 32'hFFFFFFFF; // Error/read-only indication
                        end
                        
                        default: begin
                            m_axis_tdata <= 32'hFFFFFFFF; // Error indication
                        end
                    endcase
                    
                    stream_state <= ST_RESPONSE;
                end
                
                ST_RESPONSE: begin
                    if (m_axis_tready && m_axis_tvalid) begin
                        m_axis_tvalid <= 1'b0;
                        m_axis_tlast <= 1'b0;
                        stream_state <= ST_IDLE;
                        s_axis_tready_reg <= 1'b1;
                    end
                end
                
                default: begin
                    stream_state <= ST_IDLE;
                end
            endcase
        end
    end
    
endmodule