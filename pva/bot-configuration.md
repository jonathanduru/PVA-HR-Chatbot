# Power Virtual Agents Bot Configuration

## Bot Architecture

The PVA bot serves as the conversational interface between Microsoft Teams users and the n8n backend workflow. It handles user authentication, message routing, and response formatting.

## Topic Configuration

### Main Conversation Topic

**Trigger Phrases:**
- "I have a question"
- "Help me with"
- "What is the policy"
- "Tell me about"
- Generic employee queries

**Topic Flow:**

1. **Capture User Input**
   - System variable: `System.Activity.Text`
   - Store in: `UserQuestion`

2. **Get User Context**
   - User name: `System.User.DisplayName`
   - Department: Custom user property or default value

3. **Call n8n Webhook**
   ```
   Action: HTTP Request
   Method: POST
   URL: https://your-n8n-instance.com/webhook/hr-chat-backend
   Headers:
     - Authorization: {EnvironmentVariable.HRChatPassword}
     - Content-Type: application/json
   Body:
   {
     "question": "{UserQuestion}",
     "userName": "{System.User.DisplayName}",
     "department": "{UserDepartment}"
   }
   ```

4. **Parse Response**
   - Success Path: Display answer with sources
   - Error Path: Show friendly error message

## Response Templates

### Success Response
```
Message: {HttpResponse.answer}

Sources:
- {HttpResponse.sources[0].section_title} ({HttpResponse.sources[0].relevance}% match)
- {HttpResponse.sources[1].section_title} ({HttpResponse.sources[1].relevance}% match)

Processed at: {HttpResponse.metadata.timestamp}
```

### Error Response
```
I apologize, but I'm having trouble finding that information right now. 
Please try rephrasing your question or contact HR directly for assistance.

Error details: {HttpResponse.error}
```

## Authentication Configuration

### Teams Integration
- **Authentication Type**: Teams SSO
- **User Properties**: Display name, email, department
- **Session Management**: Maintain context within conversation

### Backend Security
- **Password Storage**: Environment variable
- **Header Format**: `Authorization: your-secure-password`
- **Error Handling**: Never expose password in error messages

## Advanced Features

### Context Retention
- Store previous questions in session variables
- Allow follow-up questions
- Clear context after 30 minutes of inactivity

### Typing Indicators
```
Action: Send Activity
Activity Type: Typing
Duration: Until HTTP response received
```

### Adaptive Cards
For rich formatting of responses with sources:
```json
{
  "type": "AdaptiveCard",
  "version": "1.3",
  "body": [
    {
      "type": "TextBlock",
      "text": "{answer}",
      "wrap": true
    },
    {
      "type": "FactSet",
      "facts": [
        {
          "title": "Source",
          "value": "{source_file}"
        },
        {
          "title": "Section",
          "value": "{section_title}"
        },
        {
          "title": "Relevance",
          "value": "{relevance}%"
        }
      ]
    }
  ]
}
```

## Performance Optimizations

### Timeout Configuration
- HTTP Request timeout: 35 seconds
- User notification after 5 seconds: "Still searching for the best answer..."

### Error Recovery
- Retry logic: 2 attempts with exponential backoff
- Fallback messages for common errors
- Graceful degradation when backend unavailable

## Monitoring and Analytics

### Custom Telemetry
Track in Application Insights:
- Question frequency
- Response times
- Error rates
- User satisfaction (thumbs up/down)

### Performance Metrics
- Average response time: < 3 seconds
- Success rate: > 95%
- User engagement: Track conversation completion

## Deployment Checklist

1. **Environment Variables**
   - `HRChatPassword`: Secure password for n8n webhook
   - `N8nWebhookUrl`: Full URL to webhook endpoint
   - `EnableDebugMode`: true/false for verbose logging

2. **Teams App Manifest**
   - Bot ID and secret configured
   - Appropriate permissions granted
   - Company branding applied

3. **Testing Scenarios**
   - Valid questions with good matches
   - Questions with no relevant content
   - Authentication failures
   - Backend timeouts
   - Malformed responses

## Common Issues and Solutions

### Issue: Bot not responding
- Check webhook URL configuration
- Verify password in environment variables
- Ensure n8n workflow is active

### Issue: Slow responses
- Optimize n8n workflow execution
- Check database query performance
- Consider implementing caching

### Issue: Authentication errors
- Verify password matches between PVA and n8n
- Check header formatting
- Ensure HTTPS is used for webhook