//SystemVerilog
module bidirectional_mux (
    inout wire [7:0] port_a,       // Bidirectional port A
    inout wire [7:0] port_b,       // Bidirectional port B
    inout wire [7:0] common_port,  // Common data port
    input wire direction,          // Data flow direction: 0 - B->common, 1 - A->common
    input wire active              // Active enable signal
);

    // Internal pipeline registers for clear data flow separation
    reg [7:0] pipeline_data_in;        // Stage 1: Data sampled from source port
    reg [7:0] pipeline_data_out;       // Stage 2: Data to drive destination port
    reg pipeline_direction_d;          // Pipeline register for direction
    reg pipeline_active_d;             // Pipeline register for active

    // Internal tri-state control
    wire enable_drive_port_a;
    wire enable_drive_port_b;
    wire enable_drive_common_port;

    // Pipeline registers: Sample control and data signals
    always @(*) begin
        // Stage 1: Register control signals for timing clarity
        pipeline_direction_d = direction;
        pipeline_active_d    = active;
    end

    // Stage 1: Sample data from the source port into pipeline register
    always @(*) begin
        if (pipeline_active_d) begin
            case (pipeline_direction_d)
                1'b1: pipeline_data_in = port_a; // Direction = 1: port_a is source
                1'b0: pipeline_data_in = port_b; // Direction = 0: port_b is source
                default: pipeline_data_in = 8'b0;
            endcase
        end else begin
            pipeline_data_in = 8'b0;
        end
    end

    // Stage 2: Prepare data for output
    always @(*) begin
        pipeline_data_out = pipeline_data_in;
    end

    // Tri-state drive control signals for each port
    assign enable_drive_port_a      = pipeline_active_d && !pipeline_direction_d;
    assign enable_drive_port_b      = pipeline_active_d && pipeline_direction_d;
    assign enable_drive_common_port = pipeline_active_d;

    // Structured tri-state assignments for clear data pathway
    assign port_a = enable_drive_port_a ? pipeline_data_out : 8'bz;
    assign port_b = enable_drive_port_b ? pipeline_data_out : 8'bz;

    // Drive common_port with correct source using if-else for clarity
    assign common_port = enable_drive_common_port ? (
        (pipeline_direction_d == 1'b1) ? port_a :
        (pipeline_direction_d == 1'b0) ? port_b :
        8'bz
    ) : 8'bz;

endmodule